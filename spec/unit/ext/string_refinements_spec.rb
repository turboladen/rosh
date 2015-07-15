require 'ext/string_refinements'

RSpec.describe String do
  describe '#to_safe_down_sym' do
    context 'with spaces' do
      subject { ' one two three '.to_safe_down_sym }
      it { is_expected.to eq :_one_two_three_ }
    end

    context 'with periods' do
      subject { '.one.two.three.'.to_safe_down_sym }
      it { is_expected.to eq :onetwothree }
    end

    context 'with dashes' do
      subject { '-one-two-three-'.to_safe_down_sym }
      it { is_expected.to eq :_one_two_three_ }
    end

    context 'with capitals' do
      subject { '-One-TWO-thrEE-'.to_safe_down_sym }
      it { is_expected.to eq :_one_two_three_ }
    end
  end

  describe '#rosh_safe' do
    context 'with spaces' do
      subject { ' one two three '.rosh_safe }
      it { is_expected.to eq '_one_two_three_' }
    end

    context 'with periods' do
      subject { '.one.two.three.'.rosh_safe }
      it { is_expected.to eq 'onetwothree' }
    end

    context 'with dashes' do
      subject { '-one-two-three-'.rosh_safe }
      it { is_expected.to eq '_one_two_three_' }
    end
  end

  describe '#camel_case' do
    context 'with underscores' do
      subject { '_one_two_three_'.camel_case }
      it { is_expected.to eq 'OneTwoThree' }
    end
  end

  describe '#classify' do
    subject { '_one_two_three_'.classify }
    it { is_expected.to eq :OneTwoThree }
  end

  describe '#declassify' do
    context 'no camel case' do
      subject { 'a thing'.declassify }
      it { is_expected.to eq 'a thing' }
    end

    context 'camel case, no namespace delimiter' do
      subject { 'RoshThing'.declassify }
      it { is_expected.to eq 'rosh_thing' }
    end

    context 'camel case, namespace delimiter' do
      subject { 'RoshThing::Stuff'.declassify }
      it { is_expected.to eq 'rosh_thing.stuff' }
    end
  end

  describe '#snake_case' do
    context 'no camel case' do
      subject { 'a thing'.snake_case }
      it { is_expected.to eq 'a thing' }
    end

    context 'camel case, no namespace delimiter' do
      subject { 'RoshThing'.snake_case }
      it { is_expected.to eq 'rosh_thing' }
    end

    context 'camel case, namespace delimiter' do
      subject { 'RoshThing::Stuff'.snake_case }
      it { is_expected.to eq 'rosh_thing/stuff' }
    end
  end
end
