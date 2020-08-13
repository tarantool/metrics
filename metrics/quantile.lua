local fiber = require('fiber')

local quantile = {}

local function sort_samples(samples)
    table.sort(samples, function(a, b) return a.Value < b. Value end)
end

local function make_sample(value, width, delta)
    return {Value = value, Width = width, Delta = delta}
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
	self:merge(self.b)
	self.b = {}
end

function stream:maybeSort()
	if not self.sorted then
		self.sorted = true
		sort_samples(self.b)
    end
end

function stream:flushed()
    return #self.stream.l > 0
end

function stream:merge(samples)
	local s = self.stream

	local i = 1
    local r = 0
    for _, sample in ipairs(samples) do
        if i % 500 == 0 then
            fiber.yield()
        end
		for j = i, #s.l do
            local c = s.l[j]
			if c.Value > sample.Value then
                table.insert(s.l, j, make_sample(sample.Value, sample.Width, s.f(s, r) - 1))

				i = j + 1
				goto inserted
            end
			r = r + c.Width
		end
		table.insert(s.l, make_sample(sample.Value, sample.Width, 0))
		i = i + 1
	::inserted::
		s.n = s.n + sample.Width
	end
end

function stream:query(q)
    local s = self.stream
    local t = q * s.n
	t = t + s.f(s, t) / 2

    local p = make_sample(-math.huge, 0, 0)
	local r = 0
	for i = 1, #self.stream.l do
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
    if #s.l < 2 then
		return
	end
	local x = s.l[#s.l]
	local xi = #s.l
	local r = s.n - x.Width

    for i = #s.l - 1, 1, -1 do
        if i % 500 == 0 then
            fiber.yield()
        end
		local c = s.l[i]
		if c.Width + x.Width + x.Delta <= s.f(s, r) then
			x.Width = x.Width + c.Width
            s.l[xi] = x
			table.remove(s.l, i)
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
	table.insert(stream.b, sample)
	stream.sorted = false
	if #stream.b == stream.__max_samples then
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
		local l = #stream.b
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
    stream.stream.l = {}
    stream.stream.n = 0
	stream.b = {}
end

return quantile
