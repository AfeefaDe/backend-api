FactoryGirl.define do

  factory :facet, class: DataPlugins::Facet::Facet do
    title 'facet generated by factory'

    transient do
      owner_types []
    end

    after(:build) do |facet, evaluator|
      facet.owner_types = evaluator.owner_types.map do |owner_type|
        DataPlugins::Facet::FacetOwnerType.new(owner_type: owner_type)
      end
    end

    factory :facet_with_items do
      transient do
        facet_items_count 2
      end
      after(:create) do |facet, evaluator|
        create_list(:facet_item, evaluator.facet_items_count, facet: facet)
      end
    end

    factory :facet_with_items_and_sub_items do
      transient do
        facet_items_count 2
        sub_items_count 2
      end

      after(:create) do |facet, evaluator|
        create_list(:facet_item_with_sub_items, evaluator.facet_items_count, facet: facet, sub_items_count: evaluator.sub_items_count)
      end
    end
  end

end
