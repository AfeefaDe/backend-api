FactoryBot.define do

  factory :facet_item, class: DataPlugins::Facet::FacetItem do
    title { 'facet generated by factory' }
    association :facet, factory: :facet

    factory :facet_item_with_sub_items do
      transient do
        sub_items_count { 2 }
      end
      after(:create) do |facet_item, evaluator|
        create_list(:facet_item, evaluator.sub_items_count, facet: facet_item.facet, parent: facet_item)
      end
    end
  end

end
