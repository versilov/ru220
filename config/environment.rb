# encoding: utf-8
# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Ru220::Application.initialize!

WillPaginate::ViewHelpers.pagination_options[:prev_label] = '<< Предыдущая'
WillPaginate::ViewHelpers.pagination_options[:next_label] = 'Следующая >>'   
