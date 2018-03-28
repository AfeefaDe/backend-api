FactoryGirl.define do

  factory :offer, class: DataModules::Offer::Offer do
    title 'offer generated by factory'

    after(:build) do |offer|
      if !offer.actor_id
        orga = create(:orga_with_random_title)
        offer.actor_id = orga.id
      end
    end
  end
end