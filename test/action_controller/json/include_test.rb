require 'test_helper'

module ActionController
  module Serialization
    class Json
      class IncludeTest < ActionController::TestCase
        INCLUDE_STRING = 'posts.comments'
        INCLUDE_HASH = { posts: :comments }
        DEEP_INCLUDE = 'posts.comments.author'

        class IncludeTestController < ActionController::Base
          def setup_data
            ActionController::Base.cache_store.clear

            @author = Author.new(id: 1, name: 'Steve K.')

            @post = Post.new(id: 42, title: 'New Post', body: 'Body')
            @first_comment = Comment.new(id: 1, body: 'ZOMG A COMMENT')
            @second_comment = Comment.new(id: 2, body: 'ZOMG ANOTHER COMMENT')

            @post.comments = [@first_comment, @second_comment]
            @post.author = @author

            @first_comment.post = @post
            @second_comment.post = @post

            @blog = Blog.new(id: 1, name: 'My Blog!!')
            @post.blog = @blog
            @author.posts = [@post]

            @first_comment.author = @author
            @second_comment.author = @author
            @author.comments = [@first_comment, @second_comment]
            @author.roles = []
            @author.bio = {}
          end

          def render_without_include
            setup_data
            render json: @author, adapter: :json
          end

          def render_resource_with_include_hash
            setup_data
            render json: @author, include: INCLUDE_HASH, adapter: :json
          end

          def render_resource_with_include_string
            setup_data
            render json: @author, include: INCLUDE_STRING, adapter: :json
          end

          def render_resource_with_deep_include
            setup_data
            render json: @author, include: DEEP_INCLUDE, adapter: :json
          end
        end

        tests IncludeTestController

        def test_render_without_include
          get :render_without_include
          response = JSON.parse(@response.body)
          expected = {
            'author' => {
              'id' => 1,
              'name' => 'Steve K.',
              'posts' => [
                {
                  'id' => 42, 'title' => 'New Post', 'body' => 'Body'
                }
              ],
              'roles' => [],
              'bio' => {}
            }
          }

          assert_equal(expected, response)
        end

        def test_render_with_default_include_tree_hash
          with_default_include_tree INCLUDE_HASH do
            get :render_without_include
            response = JSON.parse(@response.body)

            assert_equal(expected_include_response, response)
          end
        end

        def test_render_resource_with_include_hash
          get :render_resource_with_include_hash
          response = JSON.parse(@response.body)

          assert_equal(expected_include_response, response)
        end

        def test_render_with_default_include_tree_string
          with_default_include_tree INCLUDE_STRING do
            get :render_without_include
            response = JSON.parse(@response.body)
            assert_equal(expected_include_response, response)
          end
        end

        def test_render_resource_with_include_string
          get :render_resource_with_include_string

          response = JSON.parse(@response.body)

          assert_equal(expected_include_response, response)
        end

        def test_render_with_default_include_tree_deep_include
          with_default_include_tree DEEP_INCLUDE do
            get :render_without_include
            response = JSON.parse(@response.body)
            assert_equal(expected_deep_include_response, response)
          end
        end

        def test_render_resource_with_deep_include
          get :render_resource_with_deep_include

          response = JSON.parse(@response.body)

          assert_equal(expected_deep_include_response, response)
        end

      private

        def expected_include_response
          {
            'author' => {
              'id' => 1,
              'name' => 'Steve K.',
              'posts' => [
                {
                  'id' => 42, 'title' => 'New Post', 'body' => 'Body',
                  'comments' => [
                    {
                      'id' => 1, 'body' => 'ZOMG A COMMENT'
                    },
                    {
                      'id' => 2, 'body' => 'ZOMG ANOTHER COMMENT'
                    }
                  ]
                }
              ]
            }
          }
        end

        def expected_deep_include_response
          {
            'author' => {
              'id' => 1,
              'name' => 'Steve K.',
              'posts' => [
                {
                  'id' => 42, 'title' => 'New Post', 'body' => 'Body',
                  'comments' => [
                    {
                      'id' => 1, 'body' => 'ZOMG A COMMENT',
                      'author' => {
                        'id' => 1,
                        'name' => 'Steve K.'
                      }
                    },
                    {
                      'id' => 2, 'body' => 'ZOMG ANOTHER COMMENT',
                      'author' => {
                        'id' => 1,
                        'name' => 'Steve K.'
                      }
                    }
                  ]
                }
              ]
            }
          }
        end

        def with_default_include_tree(include_tree)
          original = ActiveModel::Serializer.config.default_include_tree
          ActiveModel::Serializer.config.default_include_tree = include_tree
          yield
        ensure
          ActiveModel::Serializer.config.default_include_tree = original
        end
      end
    end
  end
end
