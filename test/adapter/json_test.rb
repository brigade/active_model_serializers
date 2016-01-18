require 'test_helper'

module ActiveModel
  class Serializer
    module Adapter
      class JsonTest < ActiveSupport::TestCase
        def setup
          ActionController::Base.cache_store.clear
          @author = Author.new(id: 1, name: 'Steve K.')
          @post = Post.new(id: 1, title: 'New Post', body: 'Body')
          @first_comment = Comment.new(id: 1, body: 'ZOMG A COMMENT')
          @second_comment = Comment.new(id: 2, body: 'ZOMG ANOTHER COMMENT')
          @post.comments = [@first_comment, @second_comment]
          @first_comment.post = @post
          @second_comment.post = @post
          @post.author = @author
          @blog = Blog.new(id: 1, name: 'My Blog!!')
          @post.blog = @blog

          @serializer = PostSerializer.new(@post)
          @adapter = ActiveModel::Serializer::Adapter::Json.new(@serializer)

          @expected_post_body = {
            id: 1,
            reviews: [{ id: 1, body: 'ZOMG A COMMENT' },
                      { id: 2, body: 'ZOMG ANOTHER COMMENT' }
                    ],
            writer: { id: 1, name: 'Steve K.' },
            site: { id: 1, name: 'My Blog!!' }
          }
        end

        def test_has_many
          assert_equal([
                         { id: 1, body: 'ZOMG A COMMENT' },
                         { id: 2, body: 'ZOMG ANOTHER COMMENT' }
                       ], @adapter.serializable_hash[:post][:comments])
        end

        def test_custom_keys
          serializer = PostWithCustomKeysSerializer.new(@post)
          adapter = ActiveModel::Serializer::Adapter::Json.new(serializer)

          assert_equal({ post: @expected_post_body }, adapter.serializable_hash)
        end

        def test_root_false
          serializer = PostWithCustomKeysSerializer.new(@post)
          adapter = ActiveModel::Serializer::Adapter::Json.new(serializer)

          assert_equal(@expected_post_body, adapter.serializable_hash(root: false))
        end
      end
    end
  end
end
