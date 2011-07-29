# encoding: utf-8

require 'test_helper'

class ArticlesControllerTest < ActionController::TestCase
  setup do
    @article = articles(:about)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:articles)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create article" do
    # make alias unique
    @article.alias = 'about2'
    assert_difference('Article.count') do
      post :create, :article => @article.attributes
    end

    assert_redirected_to article_path(assigns(:article).alias)
  end

  test "should show article" do
    get :show, :id => @article.to_param
    assert_response :success
    assert_select '.gold-button', /Купить/
  end

  test "should get edit" do
    get :edit, :id => @article.to_param
    assert_response :success
  end

  test "should update article" do
    put :update, :id => @article.to_param, :article => @article.attributes
    assert_redirected_to article_path(assigns(:article).alias)
  end

  test "should destroy article" do
    assert_difference('Article.count', -1) do
      delete :destroy, :id => @article.to_param
    end

    assert_redirected_to articles_path
  end
  
  test 'should fail with alias already exists' do
    assert_no_difference 'Article.count' do
      post :create, :article => @article.attributes
    end
    
    assert_template 'articles/new'
  end
end
