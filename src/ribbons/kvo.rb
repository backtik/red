class Red::MethodCompiler
  module KVO
    def kvo_add_observer
      <<-END
        function kvo_add_observer(subject, observed_property, observer) {
          subject.observers[observed_property] ? subject.observers[observed_property].push(observer) : subject.observers[observed_property] = [observer];
        }
      END
    end
    
    def kvo_notifiy_observers
      add_function :kvo_value_updated_for_attribute
      <<-END
        function kvo_notifiy_observers(subject, observed_property, new_value) {
          observers = subject.observers[observed_property];
          return if(!observers);
          
          for(var i = 0, l = observers.length; i < l; i++) {
            kvo_value_updated_for_attribute(observers[i], observed_property, new_value);
          }
        }
      END
    end
    
    def kvo_value_updated_for_attribute
      <<-END
        function kvo_value_updated_for_attribute(observer, observed_property, new_value) {
          console.log("notified observer")
        }
      END
    end
  end
end