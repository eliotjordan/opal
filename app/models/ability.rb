class Ability
  include Hydra::Ability

  include CurationConcerns::Ability
  include GeoConcerns::Ability

  # Define any customized permissions here.
  def custom_permissions
    # Limits deleting objects to a the admin user
    #
    # if current_user.admin?
    #   can [:destroy], ActiveFedora::Base
    # end

    # Limits creating new objects to a specific group
    #
    # if user_groups.include? 'special_group'
    #   can [:create], ActiveFedora::Base
    # end
  end

  # Abilities that should only be granted to admin users
  def admin_permissions
    can [:manage], :all
  end
end
