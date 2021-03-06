module MailForm
  class Base
    include ActiveModel::Conversion
    extend ActiveModel::Naming
    extend ActiveModel::Translation
    include ActiveModel::Validations
    include ActiveModel::AttributeMethods

    attribute_method_prefix 'clear_'
    attribute_method_suffix '?'

    class_attribute :attribute_names
    self.attribute_names = []

    def self.attributes(*names)
      attr_accessor(*names)
      define_attribute_methods(names)
      self.attribute_names += names
    end

    include MailForm::Validators

    # 1) Add callbacks behavior
    extend ActiveModel::Callbacks

    # 2) Define the callbacks. The line below will create both before_deliver
    # and after_deliver callbacks with the same semantics as in Active Record
    define_model_callbacks :deliver
    # 3) Change deliver to run the callbacks
    def deliver
      if valid?
        run_callbacks(:deliver) do
          MailForm::Notifier.contact(self).deliver
        end
      else
        false
      end
    end

    def initialize(attributes = {})
      attributes.each do |attr, value|
        self.public_send("#{attr}=", value)
      end if attributes
    end

    def persisted?
      false
    end

    protected

    def clear_attribute(attribute)
      send("#{attribute}=", nil)
    end

    def attribute?(attribute)
      send(attribute).present?
    end
  end
end