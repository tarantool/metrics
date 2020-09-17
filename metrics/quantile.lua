local fiber = require('fiber')
local ffi = require('ffi')

local quantile = {}

ffi.cdef[[
	typedef struct {int Delta, Width; double Value; } sample;
]]

local sample_constructor = ffi.metatype('sample', {})

local function quicksort(array, low, high)
	assert(low >= 0, 'Low bound must be non-negative')
	if high - low < 1 then
		return array
	end
	local pivot = low
	for i = low + 1, high do
		if array[i] <= array[pivot] then
			if i == pivot + 1 then
				array[pivot], array[pivot + 1] = array[pivot + 1], array[pivot]
			else
				array[pivot], array[pivot + 1], array[i] = array[i], array[pivot], array[pivot + 1]
			end
			pivot = pivot + 1
	  end
	end
	array = quicksort(array, low, pivot - 1)
	return quicksort(array, pivot + 1, high)
end

quantile.quicksort = quicksort

local function make_sample(value, width, delta)
	return sample_constructor(delta or 0, width or 0, value)
end

local inf_obj = make_sample(math.huge)

local function insert_sample(sample_obj, value, width, delta)
	sample_obj.Value = value
	sample_obj.Width = width
	sample_obj.Delta = delta
end

local stream = {}

-- Stream computes quantiles for a stream of float64s.
function stream.new(f, max_samples)
    if not max_samples then
        max_samples = 500
	end
	assert(max_samples > 0, 'max_samples must be positive')
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
	self:maybe_sort()
	self:merge(self.b, self.b_len)
	self.b_len = 0
end

function stream:maybe_sort()
	if not self.sorted and self.b_len > 1 then
		self.sorted = true
		quicksort(self.b, 0, self.b_len - 1)
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

function stream:sample_insert(value, width, delta, pos)
	local arr = self.stream.l
	local len = self.stream.l_len
	local cap = self.stream.l_cap
	local do_shift = true
	if not pos then
		pos = len + 1
		do_shift = false
	end
	if len == cap then
		cap = math.modf(cap * 1.5)
		local new_arr = ffi.new('sample[?]',  cap + 2)

		for i = 0, pos - 1 do
			sample_copy(new_arr[i], arr[i])
		end
		insert_sample(new_arr[pos], value, width, delta )
		for i = pos + 1, len do
			sample_copy(new_arr[i], arr[i-1])
		end
		for i = len + 1, cap + 1 do
			new_arr[i] = inf_obj
		end
		self.stream.l_cap = cap
		self.stream.l = new_arr
		return
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
                self:sample_insert(sample, 1, s.f(s, r) - 1, j)
				s.l_len = s.l_len + 1

				i = j + 1
				goto inserted
            end
			r = r + c.Width
		end
		self:sample_insert(sample, 1, 0)
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
	self.compress_cnt = 0
end

function quantile.NewTargeted(quantiles, max_samples)
	local qs={}
	local epss = {}
	for q, eps in pairs(quantiles) do
		assert(q >= 0 and q <= 1, 'Quantile must be in [0; 1]')
		table.insert(qs, q)
		table.insert(epss, eps)
	end
	local len = #qs
	local function fun(s, r)
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
	local s = stream.new(fun, max_samples)
	s.b = ffi.new('double[?]', s.__max_samples)

	for i = 0, s.__max_samples - 1 do
        s.b[i] = math.huge
	end

	local minf_obj = make_sample(-math.huge)

	s.stream.l = ffi.new('sample[?]', s.__max_samples * 2 + 2)
	s.stream.l[0] = minf_obj
	for i = 1, s.__max_samples * 2 + 1 do
        s.stream.l[i] = inf_obj
	end
	s.b_len = 0
	s.stream.l_len = 0
	s.stream.l_cap = s.__max_samples * 2
	s.compress_cnt = 0
	return s
end

-- Insert inserts v into the stream.
function quantile.Insert(stream_obj, v)
	stream_obj.b[stream_obj.b_len] = v
	stream_obj.b_len = stream_obj.b_len + 1
	stream_obj.compress_cnt = stream_obj.compress_cnt + 1
	stream_obj.sorted = false
	if stream_obj.b_len == stream_obj.__max_samples or
		stream_obj.compress_cnt == stream_obj.__max_samples then
		stream_obj:flush()
		stream_obj:compress()
    end
end

-- Query returns the computed qth percentiles value. If s was created with
-- NewTargeted, and q is not in the set of quantiles provided a priori, Query
-- will return an unspecified result.
function quantile.Query(stream_obj, q)
	if not stream_obj:flushed() then
		-- Fast path when there hasn't been enough data for a flush;
		-- this also yields better accuracy for small sets of data.
		local l = stream_obj.b_len
		local i = math.modf(l * q)
		stream_obj:maybe_sort()
		return stream_obj.b[i]
	end
	stream_obj:flush()
	return stream_obj:query(q)
end


-- Reset reinitializes and clears the list reusing the samples buffer memory.
function quantile.Reset(stream_obj)
    stream_obj.stream.n = 0
	stream_obj.b_len = 0
	stream_obj.stream.l_len = 0
end

return quantile
