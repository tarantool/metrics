local fiber = require('fiber')
local ffi = require('ffi')

local quantile = {}
ffi.cdef[[
	typedef struct {int Delta, Width; double Value; } sample;
	void qsort(void *base, size_t nitems, size_t size, int (*compar)(const void *, const void*));
	int cmpfunc (const void * a, const void * b);
]]
local y = ffi.load('metrics/libquantile.so')

local sample = ffi.metatype('sample', {})

local DOUBLE_SIZE = ffi.sizeof('double')

local function sort_samples(samples, len)
	ffi.C.qsort(samples, len, DOUBLE_SIZE, y.cmpfunc)
end

local function make_sample(value, width, delta)
	return sample(delta or 0, width or 0, value)
end

local function insert_sample(sample, value, width, delta)
	sample.Value = value
	sample.Width = width
	sample.Delta = delta
end

local stream = {}

-- Stream computes quantiles for a stream of float64s.
function stream.new(f, max_samples)
    if not max_samples then
        max_samples = 200
    end
	return setmetatable({
        stream = {
			f = f,
			l = {},
			n = 0,
        },
        b = {},
        sorted = true,
        __max_samples = max_samples,
    }, { __index = stream })
end

function stream:flush()
	self:maybeSort()
	self:merge(self.b, self.b_len)
	self.b_len = 0
end

function stream:maybeSort()
	if not self.sorted then
		self.sorted = true
		sort_samples(self.b, self.__max_samples)
    end
end

function stream:flushed()
    return self.stream.l_len > 0
end

local function sample_copy(dst, src)
	dst.Value = src.Value
	dst.Width = src.Width or 0
	dst.Delta = src.Delta or 0
end

local ins_cnt = 0
local function sample_insert(arr, value, width, delta, len, pos)
	local do_shift = true
	if not pos then
		pos = len + 1
		do_shift = false
	end
	if do_shift  then
		for i = len + 1, pos + 1, -1 do
			sample_copy(arr[i], arr[i-1])
		end
	end
    insert_sample(arr[pos], value, width, delta )
end

local function sample_remove(arr, len, pos)
	for i = pos, len - 1 do
		sample_copy(arr[i], arr[i+1])
	end
	arr[len].Value = math.huge
end

function stream:merge(samples, len)
	local s = self.stream

	local i = 1
    local r = 0
    for z = 1, len do
        if i % 1000 == 0 then
            fiber.yield()
		end
		local sample = samples[z-1]
		for j = i, s.l_len do
            local c = s.l[j]
			if c.Value > sample then
                sample_insert(s.l, sample, 1, s.f(s, r) - 1, s.l_len, j)
				s.l_len = s.l_len + 1

				i = j + 1
				goto inserted
            end
			r = r + c.Width
		end
		sample_insert(s.l, sample, 1, 0, s.l_len)
		s.l_len = s.l_len + 1
		i = i + 1
	::inserted::
		s.n = s.n + 1
	end
end

function stream:query(q)
    local s = self.stream
    local t = q * s.n
	t = t + s.f(s, t) / 2

    local p = s.l[0]
	local r = 0
	for i = 1, s.l_len do
        if i % 500 == 0 then
            fiber.yield()
        end
        local c = s.l[i]
        if r + c.Width + c.Delta > t then
            return p.Value
		end
		r = r + p.Width
		p = c
    end
	return p.Value
end

function stream:compress()
	local s = self.stream
    if s.l_len < 2 then
		return
	end
	local x = make_sample(0)
	sample_copy(x, s.l[s.l_len])
	local xi = s.l_len
	local r = s.n - x.Width

    for i = s.l_len - 1, 1, -1 do
        if i % 1000 == 0 then
            fiber.yield()
		end
		local c = make_sample(0)
		sample_copy(c, s.l[i])
		if c.Width + x.Width + x.Delta <= s.f(s, r) then
			x.Width = x.Width + c.Width
            sample_copy(s.l[xi], x)
			sample_remove(s.l, s.l_len, i)
			s.l_len = s.l_len - 1

			xi = xi - 1
		else
			x = c
			xi = i
        end
		r = r - c.Width
	end
end

function quantile.NewTargeted(quantiles, max_samples)
	local qs={}
	local epss = {}
	for q, eps in pairs(quantiles) do
		table.insert(qs, q)
		table.insert(epss, eps)
	end
	local len = #qs
	local function f(s, r)
        local m = math.huge
        local f
		for i = 1, len do
			local q = qs[i]
			local eps = epss[i]
			if q*s.n <= r then
				f = (2 * eps * r) / q
			else
				f = (2 * eps * (s.n - r)) / (1 - q)
            end
			if math.floor(f) < m then
				m = math.floor(f)
            end
		end
		return math.max(m, 1)
	end
	local s = stream.new(f, max_samples)
	local inf_obj = make_sample(math.huge)
	local minf_obj = make_sample(-math.huge)
	s.b = ffi.new('double[?]', s.__max_samples)

	for i = 0, s.__max_samples - 1 do
        s.b[i] = math.huge
	end
	s.stream.l = ffi.new('sample[?]', s.__max_samples * 2 + 2)
	s.stream.l[0] = minf_obj
	for i = 1, s.__max_samples * 2 + 1 do
        s.stream.l[i] = inf_obj
	end
	s.b_len = 0
	s.stream.l_len = 0
	return s
end

-- Insert inserts v into the stream.
function quantile.Insert(stream, v)
	stream.b[stream.b_len] = v
	stream.b_len = stream.b_len + 1
	stream.sorted = false
	if stream.b_len == stream.__max_samples then
		stream:flush()
		stream:compress()
    end
end

-- Query returns the computed qth percentiles value. If s was created with
-- NewTargeted, and q is not in the set of quantiles provided a priori, Query
-- will return an unspecified result.
function quantile.Query(stream, q)
	if not stream:flushed() then
		-- Fast path when there hasn't been enough data for a flush;
		-- this also yields better accuracy for small sets of data.
		local l = stream.b_len
		if l == 0 then
			return 0
        end
		local i = math.modf(l * q + 1)
		stream:maybeSort()
		return stream.b[i]
	end
	stream:flush()
	return stream:query(q)
end


-- Reset reinitializes and clears the list reusing the samples buffer memory.
function quantile.Reset(stream)
    stream.stream.n = 0
	stream.b_len = 0
	stream.stream.l_len = 0
end

return quantile
