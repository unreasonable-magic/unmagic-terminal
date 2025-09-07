# frozen_string_literal: true

require_relative "../generic/keyboard"
require_relative "key_event"

module Unmagic
  module Terminal
    module Emulator
      module Kitty
        # Enhanced keyboard handler for Kitty terminal
        class Keyboard < Generic::Keyboard
          # Kitty functional key unicode mappings
          FUNCTIONAL_KEY_CODES = {
            57_344 => :escape,
            57_345 => :enter,
            57_346 => :tab,
            57_347 => :backspace,
            57_348 => :insert,
            57_349 => :delete,
            57_350 => :left,
            57_351 => :right,
            57_352 => :up,
            57_353 => :down,
            57_354 => :page_up,
            57_355 => :page_down,
            57_356 => :home,
            57_357 => :end,
            57_358 => :caps_lock,
            57_359 => :scroll_lock,
            57_360 => :num_lock,
            57_361 => :print_screen,
            57_362 => :pause,
            57_363 => :menu,
            # Function keys
            57_364 => :f1,
            57_365 => :f2,
            57_366 => :f3,
            57_367 => :f4,
            57_368 => :f5,
            57_369 => :f6,
            57_370 => :f7,
            57_371 => :f8,
            57_372 => :f9,
            57_373 => :f10,
            57_374 => :f11,
            57_375 => :f12,
            57_376 => :f13,
            57_377 => :f14,
            57_378 => :f15,
            57_379 => :f16,
            57_380 => :f17,
            57_381 => :f18,
            57_382 => :f19,
            57_383 => :f20,
            57_384 => :f21,
            57_385 => :f22,
            57_386 => :f23,
            57_387 => :f24,
            57_388 => :f25,
            57_389 => :f26,
            57_390 => :f27,
            57_391 => :f28,
            57_392 => :f29,
            57_393 => :f30,
            57_394 => :f31,
            57_395 => :f32,
            57_396 => :f33,
            57_397 => :f34,
            57_398 => :f35,
            # Keypad keys
            57_399 => :kp_0,
            57_400 => :kp_1,
            57_401 => :kp_2,
            57_402 => :kp_3,
            57_403 => :kp_4,
            57_404 => :kp_5,
            57_405 => :kp_6,
            57_406 => :kp_7,
            57_407 => :kp_8,
            57_408 => :kp_9,
            57_409 => :kp_decimal,
            57_410 => :kp_divide,
            57_411 => :kp_multiply,
            57_412 => :kp_subtract,
            57_413 => :kp_add,
            57_414 => :kp_enter,
            57_415 => :kp_equal,
            # Media keys
            57_416 => :media_play,
            57_417 => :media_pause,
            57_418 => :media_play_pause,
            57_419 => :media_reverse,
            57_420 => :media_stop,
            57_421 => :media_fast_forward,
            57_422 => :media_rewind,
            57_423 => :media_next,
            57_424 => :media_previous,
            57_425 => :media_record,
            57_426 => :media_lower_volume,
            57_427 => :media_raise_volume,
            57_428 => :media_mute,
            # Modifier keys
            57_441 => :left_shift,
            57_442 => :left_control,
            57_443 => :left_alt,
            57_444 => :left_super,
            57_445 => :left_hyper,
            57_446 => :left_meta,
            57_447 => :right_shift,
            57_448 => :right_control,
            57_449 => :right_alt,
            57_450 => :right_super,
            57_451 => :right_hyper,
            57_452 => :right_meta
          }.freeze

          # Kitty protocol flags
          DISAMBIGUATE_ESCAPES = 1
          REPORT_EVENT_TYPES = 2
          REPORT_ALTERNATE_KEYS = 4
          REPORT_ALL_KEYS_AS_ESCAPES = 8
          REPORT_ASSOCIATED_TEXT = 16

          def initialize(input: $stdin, output: $stdout)
            super
            @enhanced_mode = false
            @protocol_flags = 0
          end

          # Enable Kitty's enhanced keyboard protocol
          def enable_enhanced_mode(flags: nil)
            # Default to all useful flags including reporting all keys as escape codes
            flags ||= DISAMBIGUATE_ESCAPES | REPORT_EVENT_TYPES | REPORT_ALTERNATE_KEYS | REPORT_ALL_KEYS_AS_ESCAPES

            @output.write "\e[>#{flags}u"
            @output.flush
            @enhanced_mode = true
            @protocol_flags = flags
          end

          # Disable Kitty's enhanced keyboard protocol
          def disable_enhanced_mode
            @output.write "\e[<u"
            @output.flush
            @enhanced_mode = false
            @protocol_flags = 0
          end

          # Query current keyboard protocol state
          def query_state
            @output.write "\e[?u"
            @output.flush
            # Would need to parse response
          end

          # Push current keyboard state onto stack
          def push_state(flags: nil)
            if flags
              @output.write "\e[>#{flags}u"
            else
              @output.write "\e[>u"
            end
            @output.flush
          end

          # Pop keyboard state from stack
          def pop_state
            @output.write "\e[<u"
            @output.flush
          end

          protected

          def parse_event(raw)
            # If we're in enhanced mode and see the Kitty format, parse it
            # Two possible formats:
            # 1. Full format: CSI unicode-key-code:alternate-key-codes ; modifiers:event-type ; text-as-codepoints u
            # 2. Legacy-style with event type: CSI modifiers;modifiers:event-type key-terminator
            if @enhanced_mode
              if raw =~ /\e\[(\d+)(?::([^;]+))?(?:;(\d+)(?::(\d+))?)?(?:;([^u]+))?u/
                # New style with 'u' terminator
                parse_kitty_event(raw, ::Regexp.last_match(1), ::Regexp.last_match(2), ::Regexp.last_match(3),
                                  ::Regexp.last_match(4), ::Regexp.last_match(5))
              elsif raw =~ /\e\[(\d+);(\d+):(\d+)([A-Z~])/
                # Legacy-style enhanced format (e.g., \e[1;1:3D for key release)
                parse_legacy_kitty_event(raw, ::Regexp.last_match(1), ::Regexp.last_match(2), ::Regexp.last_match(3),
                                         ::Regexp.last_match(4))
              else
                # Fall back to generic parsing
                super
              end
            else
              # Fall back to generic parsing
              super
            end
          end

          def parse_legacy_kitty_event(raw, params, modifiers, event_type, key_char)
            # Legacy format uses the key character to determine the key
            # and embeds event type in the modifiers field
            key = case key_char
            when "A" then :up
            when "B" then :down
            when "C" then :right
            when "D" then :left
            when "H" then :home
            when "F" then :end
            when "~"
                    # Function keys and special keys use numeric codes before ~
                    case params.to_i
                    when 2 then :insert
                    when 3 then :delete
                    when 5 then :page_up
                    when 6 then :page_down
                    else raw # Unknown
                    end
            else
                    raw # Unknown sequence
            end

            # Parse event type (1=press, 2=repeat, 3=release)
            type = case event_type.to_i
            when 1 then :press
            when 2 then :repeat
            when 3 then :release
            else :press
            end

            # Parse modifiers
            modifier_bits = (modifiers.to_i - 1) if modifiers.to_i.positive?
            modifier_list = []
            if modifier_bits&.positive?
              modifier_list << :shift if modifier_bits & 1 != 0
              modifier_list << :alt if modifier_bits & 2 != 0
              modifier_list << :ctrl if modifier_bits & 4 != 0
              modifier_list << :super if modifier_bits & 8 != 0
            end

            # Create the appropriate event
            if type == :release
              KeyUpEvent.new(
                key: key,
                modifiers: modifier_list,
                raw: raw
              )
            else
              KeyDownEvent.new(
                key: key,
                modifiers: modifier_list,
                event_type: type,
                raw: raw
              )
            end
          end

          def parse_kitty_event(raw, main_code, alt_codes, modifiers, event_type, _text)
            # Parse the main Unicode codepoint
            unicode = main_code.to_i

            # Parse alternate representations (shifted key, base layout key)
            alternate_keys = alt_codes&.split(":")&.map(&:to_i) || []
            shifted_codepoint = alternate_keys[0]
            base_layout_codepoint = alternate_keys[1]

            # Parse modifiers (subtract 1 as Kitty adds 1 to avoid null bytes)
            modifier_bits = modifiers ? (modifiers.to_i - 1) : 0
            modifier_list = []
            modifier_list << :shift if modifier_bits & 1 != 0
            modifier_list << :alt if modifier_bits & 2 != 0
            modifier_list << :ctrl if modifier_bits & 4 != 0
            modifier_list << :super if modifier_bits & 8 != 0
            modifier_list << :hyper if modifier_bits & 16 != 0
            modifier_list << :meta if modifier_bits & 32 != 0

            # Parse event type
            type = case event_type&.to_i
            when 1 then :press
            when 2 then :repeat
            when 3 then :release
            else :press
            end

            # Determine the key symbol
            key = if FUNCTIONAL_KEY_CODES[unicode]
                    FUNCTIONAL_KEY_CODES[unicode]
            elsif unicode == 3
                    # Ctrl+C special case
                    :ctrl_c
            elsif unicode == 27 && !FUNCTIONAL_KEY_CODES[27]
                    # ESC key (if not already in functional keys)
                    :escape
            elsif unicode < 32
                    # Control characters: 1=Ctrl+A, 2=Ctrl+B, etc.
                    ctrl_keys = {
                      1 => :ctrl_a, 2 => :ctrl_b, 3 => :ctrl_c, 4 => :ctrl_d,
                      5 => :ctrl_e, 6 => :ctrl_f, 7 => :ctrl_g, 8 => :ctrl_h,
                      9 => :ctrl_i, 10 => :ctrl_j, 11 => :ctrl_k, 12 => :ctrl_l,
                      13 => :ctrl_m, 14 => :ctrl_n, 15 => :ctrl_o, 16 => :ctrl_p,
                      17 => :ctrl_q, 18 => :ctrl_r, 19 => :ctrl_s, 20 => :ctrl_t,
                      21 => :ctrl_u, 22 => :ctrl_v, 23 => :ctrl_w, 24 => :ctrl_x,
                      25 => :ctrl_y, 26 => :ctrl_z
                    }
                    ctrl_keys[unicode] || unicode.chr
            else
                    # Regular character
                    [ unicode ].pack("U")
            end

            # Create the appropriate event type
            if type == :release
              KeyUpEvent.new(
                key: key,
                modifiers: modifier_list,
                unicode_codepoint: unicode,
                shifted_codepoint: shifted_codepoint,
                base_layout_codepoint: base_layout_codepoint,
                raw: raw
              )
            else
              KeyDownEvent.new(
                key: key,
                modifiers: modifier_list,
                unicode_codepoint: unicode,
                shifted_codepoint: shifted_codepoint,
                base_layout_codepoint: base_layout_codepoint,
                event_type: type,
                raw: raw
              )
            end
          end
        end
      end
    end
  end
end
