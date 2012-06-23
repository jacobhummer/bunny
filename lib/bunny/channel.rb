require "thread"
require "amq/int_allocator"

module Bunny
  class Channel

    #
    # API
    #


    attr_accessor :id


    def initialize(connection = nil, id = nil)
      @connection = connection
      @id         = id || self.class.next_channel_id
      @status     = :opening

      @connection.register_channel(self)
    end


    def open
    end

    def close
    end

    def open?
      @status == :open
    end



    # @private
    # @api private
    def self.channel_id_mutex
      @channel_id_mutex ||= Mutex.new
    end

    # Returns next available channel id. This method is thread safe.
    #
    # @return [Fixnum]
    # @api public
    # @see Channel.release_channel_id
    # @see Channel.reset_channel_id_allocator
    def self.next_channel_id
      channel_id_mutex.synchronize do
        self.initialize_channel_id_allocator

        @int_allocator.allocate
      end
    end

    # Releases previously allocated channel id. This method is thread safe.
    #
    # @param [Fixnum] Channel id to release
    # @api public
    # @see Channel.next_channel_id
    # @see Channel.reset_channel_id_allocator
    def self.release_channel_id(i)
      channel_id_mutex.synchronize do
        self.initialize_channel_id_allocator

        @int_allocator.release(i)
      end
    end # self.release_channel_id(i)

    # Resets channel allocator. This method is thread safe.
    # @api public
    # @see Channel.next_channel_id
    # @see Channel.release_channel_id
    def self.reset_channel_id_allocator
      channel_id_mutex.synchronize do
        self.initialize_channel_id_allocator

        @int_allocator.reset
      end
    end # self.reset_channel_id_allocator


    # @private
    def self.initialize_channel_id_allocator
      # TODO: ideally, this should be in agreement with negotiated max number of channels of the connection,
      #       but it is possible that the value is not yet available. MK.
      max_channel     =  (1 << 16) - 1
      @int_allocator ||= AMQ::IntAllocator.new(1, max_channel)
    end # self.initialize_channel_id_allocator



    #
    # Backwards compatibility with 0.8.0
    #

    def number
      self.id
    end

    def active
      @active
    end

    def client
      @connection
    end
  end
end
