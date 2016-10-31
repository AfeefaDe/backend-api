FactoryGirl.define do

  factory :orga do

    title 'an orga'
    parent_orga { Orga.root_orga }

    factory :another_orga do
      title 'another orga'
    end

    factory :active_orga do
      title 'an active orga'
      state StateMachine::ACTIVE
    end

    factory :orga_with_admin do

      title 'orga with admin'

      transient do
        users { [build(:user)] }
      end

      after(:build) do |orga, evaluator|
        role = Role.new(title: Role::ORGA_ADMIN, user: evaluator.users.first, orga: orga)
        orga.roles << role
        evaluator.users.first.roles << role
      end

      after(:create) do |orga|
        orga.roles.map(&:save)
        orga.users.map(&:save)
      end
    end
  end


end