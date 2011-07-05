{ :ru =>
  { :i18n =>
    { :plural =>
      { :keys => [:one, :few, :other],
        :rule => lambda { |n|
          if (n % 10) == 1 && n != 11
            :one
          else
            if [2, 3, 4].include?(n % 10) &&
              ![12,13,14].include?(n % 100)
              :few
            else
              :other
            end
          end
        }
      }
    }
  }
}
