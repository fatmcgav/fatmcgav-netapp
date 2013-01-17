Puppet::Type.newtype(:netapp_snapmirror_schedule) do 
  @doc = "Manage Netapp Snapmirror schedule creation, modification and deletion."
  
  apply_to_device
  
  ensurable do
    desc "Netapp Snapmirror schedule resource state. Valid values are: present, absent."
    
    defaultto(:present)
    
    newvalue(:present) do 
      provider.create
    end
    
    newvalue(:absent) do 
      provider.destroy
    end
  end
  
  # A base class for all of the SnapSchedParam parameters, since they all have
  # similar argument checking going on.
  class SnapSchedParam < Puppet::Property
    class << self
      attr_accessor :boundaries, :default
    end
  
    # We have to override the parent method, because we consume the entire
    # "should" array
    def insync?(is)
      self.is_to_s(is) == self.should_to_s
    end
  
    # A method used to do parameter input handling. Converts integers
    # in string form to actual integers, and returns the value if it's
    # an integer or false if it's just a normal string.
    def numfix(num)
      if num =~ /^\d+$/
        return num.to_i
      elsif num.is_a?(Integer)
        return num
      else
        return false
      end
    end
  
    # Verify that a number is within the specified limits. Return the
    # number if it is, or false if it is not.
    def limitcheck(num, lower, upper)
      (num >= lower and num <= upper) && num
    end
  
    # Verify that a value falls within the specified array. Does case
    # insensitive matching, and supports matching either the entire word
    # or the first three letters of the word.
    def alphacheck(value, ary)
      tmp = value.downcase
    
      # If they specified a shortened version of the name, then see
      # if we can lengthen it (e.g., mon => monday).
      if tmp.length == 3
        ary.each_with_index { |name, index|
          if tmp.upcase == name[0..2].upcase
            return index
          end
        }
      else
        return ary.index(tmp) if ary.include?(tmp)
      end
    
      false
    end
    
    def should_to_s(newvalue = @should)
      if newvalue
        newvalue = [newvalue] unless newvalue.is_a?(Array)
        if self.name == :command or newvalue[0].is_a? Symbol
          newvalue[0]
        else
          newvalue.join(",")
        end
      else
        nil
      end
    end
    
    def is_to_s(currentvalue = @is)
      if currentvalue
        return currentvalue unless currentvalue.is_a?(Array)
    
        if self.name == :command or currentvalue[0].is_a? Symbol
          currentvalue[0]
        else
          currentvalue.join(",")
        end
      else
        nil
      end
    end
    
    def should
      if @should and @should[0] == :absent
        :absent
      else
        @should
      end
    end
    
    def should=(ary)
      super
      @should.flatten!
    end
    
    # The method that does all of the actual parameter value
    # checking; called by all of the +param<name>=+ methods.
    # Requires the value, type, and bounds, and optionally supports
    # a boolean of whether to do alpha checking, and if so requires
    # the ary against which to do the checking.
    munge do |value|
      # Support 'absent' as a value, so that they can remove
      # a value
      if value == "absent" or value == :absent
        return :absent
      end
    
      # Allow the 1-24/2 syntax
      if value =~ /^[0-9][-][0-9]{1,2}\/[0-9]+$/
        return value
      end
    
      # Allow ranges of 1-24
      if value =~ /^[0-9]+-[0-9]{1,2}+$/
        return value
      end
    
      # Allow comma seperated list with optional double digits
      if value =~ /^([0-9]{1,2}[,])+[0-9]{1,2}$/
        return value
      end
    
      # Match * and return
      if value == "*"
        return value
      end
      
      # Match - and return
      if value == "-"
        return value
      end
    
      return value unless self.class.boundaries
      lower, upper = self.class.boundaries
      retval = nil
      if num = numfix(value)
        retval = limitcheck(num, lower, upper)
      elsif respond_to?(:alpha)
        # If it has an alpha method defined, then we check
        # to see if our value is in that list and if so we turn
        # it into a number
        retval = alphacheck(value, alpha)
      end
    
      if retval
        return retval.to_s
      else
        self.fail "#{value} is not a valid #{self.class.name}"
      end
    end
  end
  #EOC
  
  newparam(:source_location) do
    desc "The source location."
  end
  
  newparam(:destination_location) do
    desc "The destination location."
    isnamevar
  end
  
  newparam(:max_transfer_rate) do 
    desc "The max transfer rate, in KB/s. Defaults to unlimited."
  end
  
  newparam(:minutes, :parent => SnapSchedParam) do 
    self.boundaries = [0, 59]
    desc "The minutes in the hour for schedule to be set.
      Can be single value between 0 and 59, 
      comma seperated list (1,7,14), 
      range (2-10),
      range with divider (1-59/3),
      * to match all
      or - to match none. "
  end
  
  newparam(:hours, :parent => SnapSchedParam) do
    self.boundaries = [1, 24]
    desc "The hour(s) in the day for schedule to be set.
      Can be single value between 1 and 24, 
      comma seperated list (1,7,14), 
      range (2-10),
      range with divider (1-24/3),
      * to match all
      or - to match none. "
  end
  
  newparam(:days_of_week, :parent => SnapSchedParam) do 
    def alpha
      %w{sunday monday tuesday wednesday thursday friday saturday}
    end
    self.boundaries = [0, 6]
    desc "The days of week for schedule to be set. 
      Can be single value between 0 and 6, inclusive, with 0 being Sunday, 
      or must be name of the day (e.g. Tuesday),
      comma sepeated list (1,3,5),
      range (2-5),
      * to match all
      or - to match none. "
  end
  
  newparam(:days_of_month, :parent => SnapSchedParam) do 
    self.boundaries = [1, 31]
    desc "The days of month for schedule to be set.
      Can be single value between 1 and 31, 
      comma seperated list (1,7,14), 
      range (2-10),
      range with divider (1-30/7),
      * to match all
      or - to match none. "
  end
  
  newparam(:restart) do
    desc "The restart mode to use when transfer interrupted. Allowed values are: always, never and restart."
    newvalues(:always, :never, :default)
    defaultto "default"
  end
  
  newparam(:connection_mode) do
    desc "The connection mode to use between source and destination."
    newvalues(:inet, :inet6)
  end
  
end