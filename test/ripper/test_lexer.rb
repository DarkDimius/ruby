# frozen_string_literal: true
begin
  require 'ripper'
  require 'test/unit'
  ripper_test = true
  module TestRipper; end
rescue LoadError
end

class TestRipper::Lexer < Test::Unit::TestCase
  def test_nested_dedent_heredoc
    bug = '[ruby-core:80977] [Bug #13536]'
    str = <<~'E'
    <<~"D"
    #{
    <<~"B"
    this must be a valid ruby
    B
    }
    D
    E
    assert_equal(str, Ripper.tokenize(str).join(""), bug)

    str = <<~'E'
    <<~"D"
    #{
    <<~"B"
      this must be a valid ruby
    B
    }
    D
    E
    assert_equal(str, Ripper.tokenize(str).join(""), bug)
  end

  def test_embedded_expr_in_heredoc
    src = <<~'E'
    <<~B
      #{1}
    B
    E
    expect = %I[
      on_heredoc_beg
      on_nl
      on_ignored_sp
      on_embexpr_beg
      on_int
      on_embexpr_end
      on_tstring_content
      on_heredoc_end
    ]
    assert_equal expect, Ripper.lex(src).map {|e| e[1]}
  end

  def test_space_after_expr_in_heredoc
    src = <<~'E'
    <<~B
     #{1} a
    B
    E
    expect = %I[
      on_heredoc_beg
      on_nl
      on_ignored_sp
      on_embexpr_beg
      on_int
      on_embexpr_end
      on_tstring_content
      on_heredoc_end
    ]
    assert_equal expect, Ripper.lex(src).map {|e| e[1]}
  end

  def test_expr_at_beginning_in_heredoc
    src = <<~'E'
    <<~B
      a
    #{1}
    B
    E
    expect = %I[
      on_heredoc_beg
      on_nl
      on_tstring_content
      on_embexpr_beg
      on_int
      on_embexpr_end
      on_tstring_content
      on_heredoc_end
    ]
    assert_equal expect, Ripper.lex(src).map {|e| e[1]}
  end

  def test_slice
    assert_equal "string\#{nil}\n",
      Ripper.slice(%(<<HERE\nstring\#{nil}\nHERE), "heredoc_beg .*? nl $(.*?) heredoc_end", 1)
  end

  def state(name)
    Ripper::Lexer::State.new(Ripper.const_get(name))
  end

  def test_state_after_ivar
    assert_equal [[1,0],:on_ivar,"@a",state(:EXPR_END)], Ripper.lex("@a").last
    assert_equal [[1,1],:on_ivar,"@a",state(:EXPR_ENDFN)], Ripper.lex(":@a").last
    assert_equal [[1,0],:on_ivar,"@1",state(:EXPR_END)], Ripper.lex("@1").last
    assert_equal [[1,1],:on_ivar,"@1",state(:EXPR_ENDFN)], Ripper.lex(":@1").last
  end

  def test_state_after_cvar
    assert_equal [[1,0],:on_cvar,"@@a",state(:EXPR_END)], Ripper.lex("@@a").last
    assert_equal [[1,1],:on_cvar,"@@a",state(:EXPR_ENDFN)], Ripper.lex(":@@a").last
    assert_equal [[1,0],:on_cvar,"@@1",state(:EXPR_END)], Ripper.lex("@@1").last
    assert_equal [[1,1],:on_cvar,"@@1",state(:EXPR_ENDFN)], Ripper.lex(":@@1").last
  end
end
