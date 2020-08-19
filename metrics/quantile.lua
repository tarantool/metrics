local fiber = require('fiber')
local ffi = require('ffi')

ffi.cdef[[
	typedef struct {int Delta, Width; double Value; } sample;
	void qsort(void *base, size_t nitems, size_t size, int (*compar)(const void *, const void*));
	int cmpfunc (const void * a, const void * b);
]]
local y = ffi.load('metrics/libquantile.so')

local sample = ffi.metatype('sample', {})

local SAMPLE_SIZE = ffi.sizeof(sample(0,0,0))

local function len(x) return ffi.sizeof(x) / SAMPLE_SIZE
end

local quantile = {}

local function sort_samples(samples)
	ffi.C.qsort(samples, ffi.sizeof(samples)/SAMPLE_SIZE, SAMPLE_SIZE, y.cmpfunc)
end

local function make_sample(value, width, delta)
	return sample(delta, width, value)
end

local function new_array_sample(len)
	return ffi.cast('sample*', ffi.gc(ffi.C.malloc(SAMPLE_SIZE*len), ffi.C.free))
end

local stream = {}

-- Stream computes quantiles for a stream of float64s.
function stream.new(f, max_samples)
    if not max_samples then
        max_samples = 500
    end
	return setmetatable({
        stream = {
			f = f,
			l = ffi.new('sample[?]', 0),
			n = 0,
        },
		b = ffi.new('sample[?]', 0),
        sorted = true,
        __max_samples = max_samples,
    }, { __index = stream })
end

function stream:flush()
	self:maybeSort()
	self:merge(self.b)
	self.b = ffi.new('sample[?]', 0)
end

function stream:maybeSort()
	if not self.sorted then
		self.sorted = true
		sort_samples(self.b)
    end
end

function stream:flushed()
    return len(self.stream.l) > 0
end

local function sample_insert(arr, val, pos)
	local len = ffi.sizeof(arr) / SAMPLE_SIZE
	if not pos then
		pos = len
	end
	local new_arr = ffi.new('sample[?]', len + 1)
	for i = 0, pos - 1 do
		new_arr[i] = arr[i]
	end
	new_arr[pos] = val
	for i = pos + 1, len do
		new_arr[i] = arr[i-1]
	end
	return new_arr
end

local function sample_remove(arr, pos)
	local len = ffi.sizeof(arr) / SAMPLE_SIZE
	if not pos then
		error('Required argement pos is missing')
	end

	local new_arr = ffi.new('sample[?]', len - 1)

	for i = 0, pos do
		new_arr[i] = arr[i]
	end
	for i = pos + 1, len - 1 do
		new_arr[i - 1] = arr[i]
	end
	return new_arr

end

function stream:merge(samples)
	local s = self.stream

	local i = 1
	local r = 0

    for z = 0, len(samples)-1 do
        if i % 500 == 0 then
			fiber.yield()
        end
		for j = i, len(s.l) - 1 do
	        local c = s.l[j]
			if c.Value > samples[z].Value then
				s.l = sample_insert(s.l, make_sample(samples[z].Value, samples[z].Width, s.f(s, r) - 1), j)

				i = j + 1
				goto inserted
            end
			r = r + c.Width
		end
		s.l = sample_insert(s.l, make_sample(samples[z].Value, samples[z].Width, 0))
		i = i + 1
	::inserted::
		s.n = s.n + samples[z].Width
	end
end

function stream:query(q)
    local s = self.stream
    local t = q * s.n
	t = t + s.f(s, t) / 2

    local p = make_sample(-math.huge, 0, 0)
	local r = 0
	for i = 0, len(self.stream.l) - 1  do
	    if i % 500 == 0 then
            fiber.yield()
        end
		local c = self.stream.l[i]
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
    if len(s.l) < 2 then
		return
	end
	local x = s.l[len (s.l)]
	local xi = len(s.l)
	local r = s.n - x.Width

    for i = len(s.l) - 2, 0, -1 do
	    if i % 500 == 0 then
            fiber.yield()
        end
		local c = s.l[i]
		if c.Width + x.Width + x.Delta <= s.f(s, r) then
			x.Width = x.Width + c.Width
			s.l[xi] = x

			s.l = sample_remove(s.l, i)
			xi = xi - 1
		else
			x = c
			xi = i
        end
		r = r - c.Width
	end
end

function quantile.NewTargeted(quantiles)
	local function f(s, r)
        local m = math.huge
        local f
		for q, eps in pairs(quantiles) do
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
	return stream.new(f)
end


-- Insert inserts v into the stream.
function quantile.Insert(stream, v)
	local sample = make_sample(v, 1, 0)
	stream.b = sample_insert(stream.b, sample)
	stream.sorted = false
	if len(stream.b) == stream.__max_samples then
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
		local l = len(stream.b)
		if l == 0 then
			return 0
        end
		local i = math.modf(l * q + 1)
		stream:maybeSort()
		return stream.b[i].Value
	end
	stream:flush()
	return stream:query(q)
end

-- Merge merges samples into the underlying streams samples.
function quantile.Merge(stream, samples)
	sort_samples(samples)
	stream:merge(samples)
end

-- Reset reinitializes and clears the list reusing the samples buffer memory.
function quantile.Reset(stream)
    stream.stream.l = ffi.new('sample[?]', 0)
    stream.stream.n = 0
	stream.b = ffi.new('sample[?]', 0)
end

return quantile
