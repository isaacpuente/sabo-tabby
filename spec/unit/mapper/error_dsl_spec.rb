# frozen_string_literal: true

require "spec/shared/test_data"
require "sabo_tabby/mapper/error"
require "sabo_tabby/mapper/standard_error"

RSpec.describe SaboTabby::Mapper::Error do
  let(:validation_error_mapper) { ValidationErrorMapper }
  let(:error_mapper) { SaboTabby::Mapper::StandardError }

  describe ".resource" do
    let(:dsl_methods) {
      {
        type: nil,
        status: 400,
        code: "",
        title: "Error",
        detail: nil
      }
    }
    context "without arg" do
      let(:error_mapper) { WithoutArgErrorMapper }

      it "is nil" do
        expect(error_mapper.resource).to be_nil
      end
    end
    context "with arg" do
      it "returns defined value" do
        expect(error_mapper.resource).to eq(:standard_error)
      end
    end
    context "without block" do
      let(:error_mapper) { WithoutBlockErrorMapper }
      it "initializes all settings to default values" do
        dsl_methods.each do |method, value|
          case method
          when :detail
            expect(error_mapper.config).to respond_to(:_detail)
            expect(error_mapper.config.send(:_detail)).to be_a(Proc)
          else
            expect(error_mapper.config).to respond_to("_#{method}")
            expect(error_mapper.config.send("_#{method}")).to eq(value)
          end
        end
      end
    end
    context "with block" do
      let(:dsl_methods) {
        {
          type: :validation_error,
          status: 422,
          code: 3,
          title: "Validation error",
          detail: nil
        }
      }
      it "initializes all settings" do
        dsl_methods.each do |method, value|
          expect(validation_error_mapper.config).to respond_to("_#{method}")
          case method
          when :detail
            expect(validation_error_mapper.config.send(:_detail)).to be_a(Proc)
          else
            expect(validation_error_mapper.config.send("_#{method}")).to eq(value)
          end
        end
      end
    end
  end

  describe ".status" do
    it "sets status" do
      expect(validation_error_mapper.status).to eq(422)
    end
    context "not set" do
      it "sets default status" do
        expect(error_mapper.status).to eq(400)
      end
    end
  end

  describe ".type" do
    it "sets type" do
      expect(validation_error_mapper.type).to eq(:validation_error)
    end
    context "not set" do
      it "sets default type" do
        expect(error_mapper.type).to eq(nil)
      end
    end
  end

  describe ".code" do
    it "sets code" do
      expect(validation_error_mapper.code).to eq(3)
    end
    context "not set" do
      it "sets default code" do
        expect(error_mapper.code).to eq("")
      end
    end
  end

  describe ".title" do
    it "sets title" do
      expect(validation_error_mapper.title).to eq("Validation error")
    end
    context "not set" do
      it "sets default title" do
        expect(error_mapper.title).to eq("Error")
      end
    end
  end

  describe ".detail" do
    it "sets detail" do
      expect(validation_error_mapper.detail).to be_a(Proc)
    end
    context "not set" do
      let(:error_mapper) { WithoutBlockErrorMapper }

      it "sets default block" do
        expect(error_mapper.detail).to be_a(Proc)
      end
    end
  end

  describe ".origin" do
    it "sets origin" do
      expect(validation_error_mapper.origin).to be_a(Proc)
    end
    context "not set" do
      let(:error_mapper) { WithoutBlockErrorMapper }

      it "sets default block" do
        expect(error_mapper.origin).to be_a(Proc)
      end
    end
  end
end
