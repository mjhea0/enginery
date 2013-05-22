module Enginery
  module Helpers
    
    def activerecord_associations setups = {}
      ORM_ASSOCIATIONS.inject([]) do |lines,a|
        (setups[a]||[]).each do |s|
          line, input = nil, s.split(':')
          target = input[0]
          if target =~ /\W/
            o '*** WARN: invalid association target "%s", association not added ***' % target
          else
            line = '%s :%s' % [a, target]
            if through = input[1].to_s =~ /through/ && input[2]
              if through =~ /\W/
                o '*** WARN: invalid :through option "%s", association not added ***' % through
                line = nil
              else
                line << ', through: :%s' % through
              end
            end
          end
          lines.push(line) if line
        end
        lines
      end
    end

    def datamapper_associations setups = {}
      ORM_ASSOCIATIONS.inject([]) do |lines,a|
        (setups[a]||[]).each do |s|
          line, input = nil, s.split(':')
          target = input[0]
          if target =~ /\W/
            o '*** WARN: invalid association target "%s", association not added ***' % target
          else
            if a == :has_one
              line = 'has 1, :%s' % target
            elsif a =~ /has_(and|many)/
              line = 'has n, :%s' % target
            else
              line = '%s :%s' % [a, target]
            end
            if through = input[1].to_s =~ /through/ && input[2]
              if through =~ /\W/
                o '*** WARN: invalid :through option "%s", association not added ***' % through
                line = nil
              else
                line << ', through: :%s' % through
              end
            end
          end
          lines.push(line) if line
        end
        lines
      end
    end

    def sequel_associations setups = {}
      ORM_ASSOCIATIONS.inject([]) do |lines,a|
        (setups[a]||[]).each do |s|
          line, input = nil, s.split(':')
          target = input[0]
          if target =~ /\W/
            o '*** WARN: invalid association target "%s", association not added ***' % target
          else
            case a
            when :belongs_to
              line = 'many_to_one :%s' % target
            when :has_one
              line = 'one_to_one :%s' % target
            when :has_many
              line = 'one_to_many :%s' % target
            when :has_and_belongs_to_many
              line = 'many_to_many :%s' % target
            end
            if through = input[1].to_s =~ /through/ && input[2]
              o '*** INFO: Sequel does not support :through option, ignoring ***' % through
            end
          end
          lines.push(line) if line
        end
        lines
      end
    end
  end
end
