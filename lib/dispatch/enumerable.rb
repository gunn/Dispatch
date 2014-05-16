# Additional parallel operations for any object supporting +each+

module Dispatch
  class Queue
    def fake_apply(n, &block)
      g = Dispatch::Group.new
      n.times do |i|
        async(g) { block.call(i) }
      end
      g.wait
    end
  end
end


class Integer
  # Applies the +&block+ +Integer+ number of times in parallel
  # -- passing in stride (default 1) iterations at a time --
  # on a concurrent queue of the given (optional) +priority+
  #
  #   @sum = 0
  #   10.p_times(3) { |j| @sum += j }
  #   p @sum # => 55
  #
  def p_times(stride=1, priority=nil, &block)
    n_times = self.to_int
    q = Dispatch::Queue.concurrent(priority)
    return q.apply(n_times, &block) if stride == 1

    n_strides = (n_times / stride).to_int
    block_from = Proc.new do |j0|
      lambda { |j| block.call(j0+j) }
    end
    q.fake_apply(n_strides) { |i| stride.times &block_from.call(i*stride) }
    # Runs the remainder (if any) sequentially on the current thread
    (n_times % stride).times &block_from.call(n_strides*stride)
  end
end

module Enumerable

  # Parallel +each+
  def p_each(stride=1, priority=nil,  &block)
    ary = self.to_a
    ary.count.p_times(stride, priority) { |i| block.call(ary[i]) }
  end

  # Parallel +each+
  def p_each_with_index(stride=1, priority=nil,  &block)
    ary = self.to_a
    ary.count.p_times(stride, priority) { |i| block.call(ary[i], i) }
  end

  # Parallel +collect+
  # Results match the order of the original array
  def p_map(stride=1, priority=nil,  &block)
    @p_map_result = Dispatch::Proxy.new([])
    @p_map_result_q ||= Dispatch::Queue.for(@p_map_result)
    @p_map_result_q.sync do
      self.p_each_with_index(stride, priority) { |obj, i| @p_map_result[i] = block.call(obj) }
    end
    @p_map_result.__value__
  end

  # Parallel +collect+ plus +inject+
  # Accumulates from +initial+ via +op+ (default = '+')
  # Note: each object can only run one p_mapreduce at a time
  def p_mapreduce(initial, op=:+, stride=1, priority=nil, &block)
    # Check first, since exceptions from a Dispatch block can act funky
    raise ArgumentError if not initial.respond_to? op
    @mapreduce_q ||= Dispatch::Queue.for(self)
    @mapreduce_q.sync do # in case called more than once at a time
      @mapreduce_result = initial
      q = Dispatch::Queue.for(@mapreduce_result)
      self.p_each(stride, priority) do |obj|
        val = block.call(obj)
        q.async { @mapreduce_result = @mapreduce_result.send(op, val) }
      end
      q.sync {}
      return @mapreduce_result
    end
  end

  # Parallel +select+; will return array of objects for which
  # +&block+ returns true.
  def p_find_all(stride=1, priority=nil,  &block)
    found_all = Dispatch::Proxy.new([])
    self.p_each(stride, priority) { |obj| found_all << obj if block.call(obj) }
    found_all.__value__
  end

  # Parallel +detect+; will return -one- match for +&block+
  # but it may not be the 'first'
  # Only useful if the test block is very expensive to run
  # Note: each object can only run one p_find at a time
  def p_find(stride=1, priority=nil,  &block)
    @find_q ||= Dispatch::Queue.for(self)
    @find_q.sync do
      @find_result = nil
      q = Dispatch::Queue.for(@find_result)
      self.p_each(stride, priority) do |obj|
        q.async { @find_result = obj } if @find_result.nil? and block.call(obj)
      end
      q.sync {}
      return @find_result
    end
  end
end
