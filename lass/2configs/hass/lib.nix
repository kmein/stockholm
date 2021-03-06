{ lib, ... }:
rec {
  lights = {
    bett = "0x0017880106ed3bd8";
    essen = "0x0017880108327622";
    arbeit = "0x0017880106ee2865";
    nass = "0x00178801082e9f2f";
  };

  switches = {
    dimmer = {
      bett = "0x00178801086ac38c";
      essen = "0x00178801086ad1fb";
      nass = "0x00178801086ac373";
    };
  };

  sensors = {
    movement = {
      essen = "0x0017880106f772f2";
      nass =  "0x0017880106f77f30";
    };
  };

  friendly_names =
    lib.mapAttrs' (n: v: lib.nameValuePair "light.${v}_light" { friendly_name = "l.${n}"; }) lights //
    lib.mapAttrs' (n: v: lib.nameValuePair "binary_sensor.${v}_update_available" { friendly_name = "s.${n}_up"; }) switches.dimmer //
    lib.mapAttrs' (n: v: lib.nameValuePair "binary_sensor.${v}_update_available" { friendly_name = "i.${n}_up"; }) sensors.movement //
    lib.mapAttrs' (n: v: lib.nameValuePair "binary_sensor.${v}_update_available" { friendly_name = "l.${n}_up"; }) lights //
    lib.mapAttrs' (n: v: lib.nameValuePair "sensor.${v}_linkquality" { friendly_name = "s.${n}_link"; }) switches.dimmer //
    lib.mapAttrs' (n: v: lib.nameValuePair "sensor.${v}_linkquality" { friendly_name = "i.${n}_link"; }) sensors.movement //
    lib.mapAttrs' (n: v: lib.nameValuePair "sensor.${v}_linkquality" { friendly_name = "l.${n}_link"; }) lights //
    lib.mapAttrs' (n: v: lib.nameValuePair "sensor.${v}_battery" { friendly_name = "s.${n}_bat"; }) switches.dimmer //
    lib.mapAttrs' (n: v: lib.nameValuePair "sensor.${v}_battery" { friendly_name = "i.${n}_bat"; }) sensors.movement //
    lib.mapAttrs' (n: v: lib.nameValuePair "sensor.${v}_action" { friendly_name = "s.${n}_act"; }) switches.dimmer //
    lib.mapAttrs' (n: v: lib.nameValuePair "binary_sensor.${v}_occupancy" { friendly_name = "i.${n}_move"; }) sensors.movement //
    lib.mapAttrs' (n: v: lib.nameValuePair "binary_sensor.${v}_occupancy" { friendly_name = "i.${n}_move"; }) sensors.movement //
    lib.mapAttrs' (n: v: lib.nameValuePair "sensor.${v}_temperature" { friendly_name = "i.${n}_heat"; }) sensors.movement //
    lib.mapAttrs' (n: v: lib.nameValuePair "sensor.${v}_temperature" { friendly_name = "i.${n}_heat"; }) sensors.movement //
    lib.mapAttrs' (n: v: lib.nameValuePair "sensor.${v}_illuminance" { friendly_name = "i.${n}_lux"; }) sensors.movement //
    lib.mapAttrs' (n: v: lib.nameValuePair "sensor.${v}_illuminance" { friendly_name = "i.${n}_lux"; }) sensors.movement //
    {};

  detect_movement = sensor: light: delay:
  let
    id = "${sensor}_${light}";
    sensor_ = "binary_sensor.${sensor}_occupancy";
    light_ = "light.${light}_light";
  in {
    input_boolean."${id}" = {
    };
    timer."${id}" = {
      duration = delay;
    };
    automation = [
      # {
      #   alias = "debug detect_movement";
      #   trigger = {
      #     platform = "state";
      #     entity_id = sensor_;
      #   };
      #   action = [
      #     {
      #       service = "system_log.write";
      #       data_template = {
      #         message = "XXXXXXXXXXXXXXXXXXXXXX {{ states('input_boolean.${sensor}_${light}_triggered') == 'on' }}";
      #         #message = "XXXXXXXXXXXXXXXXXXXXXX {{ state_attr('trigger.to_state.state', 'illuminance') }}";
      #       };
      #     }
      #   ];
      # }
      {
        alias = "movement reset timer ${id}";
        hide_entity = true;
        trigger = {
          platform = "state";
          entity_id = sensor_;
          from = "off";
          to = "on";
        };
        action = [
          {
            service = "timer.cancel";
            data_template.entity_id = "timer.${id}";
          }
        ];
      }
      {
        alias = "movement on ${id}";
        # hide_entity = true;
        trigger = {
          platform = "state";
          entity_id = "binary_sensor.${sensor}_occupancy";
          from = "off";
          to = "on";
        };
        condition = {
          condition = "and";
          conditions = [
            {
              condition = "template";
              value_template = "{{ trigger.to_state.attributes.illuminance < 7500 }}";
            }
            {
              condition = "template";
              value_template = "{{ states('${light_}') == 'off' }}";
            }
          ];
        };
        action = [
          {
            service = "light.turn_on";
            data_template = {
              entity_id = light_;
              brightness = "100";
            };
          }
          { delay = "0:00:02"; }
          {
            service = "input_boolean.turn_on";
            data_template.entity_id = "input_boolean.${id}";
          }
        ];
      }
      {
        alias = "movement off ${id}";
        hide_entity = true;
        trigger = {
          platform = "state";
          entity_id = sensor_;
          from = "on";
          to = "off";
        };
        condition = {
          condition = "template";
          value_template = "{{ states('input_boolean.${id}') == 'on' }}";
        };
        action = [
          {
            service = "timer.start";
            entity_id = "timer.${id}";
          }
        ];
      }
      {
        alias = "movement override ${id}";
        hide_entity = true;
        trigger = {
          platform = "state";
          entity_id = light_;
        };
        action = [
          {
            service = "input_boolean.turn_off";
            data_template.entity_id = "input_boolean.${id}";
          }
          {
            service = "system_log.write";
            data_template = {
              message = "XXXXXXXXXXXXXXXXXXXXXX {{ trigger }}";
            };
          }
        ];
      }
      {
        alias = "movement expired ${id}";
        hide_entity = true;
        trigger = {
          platform = "event";
          event_type = "timer.finished";
          event_data.entity_id = "timer.${id}";
        };
        action = [
          {
            service = "light.turn_off";
            data_template = {
              entity_id = light_;
            };
          }
          {
            service = "input_boolean.turn_off";
            data_template.entity_id = "input_boolean.${id}";
          }
        ];
      }
    ];
  };

  lightswitch = switch: light: {
    automation = [
      {
        alias = "lightswitch ${switch} turn on light ${light}";
        hide_entity = "true";
        trigger = {
          platform = "mqtt";
          topic = "zigbee/${switch}";
        };
        condition = {
          condition = "or";
          conditions = [
            {
              condition = "template";
              value_template = "{{ trigger.payload_json.action == 'on-press' }}";
            }
            {
              condition = "template";
              value_template = "{{ trigger.payload_json.action == 'up-press' }}";
            }
            {
              condition = "and";
              conditions = [
                {
                  condition = "template";
                  value_template = "{{ trigger.payload_json.action == 'down-press' }}";
                }
                {
                  condition = "template";
                  value_template = "{{ trigger.payload_json.brightness > 30 }}";
                }
              ];
            }
          ];
        };
        action = [
          {
            service = "light.turn_on";
            data_template = {
              entity_id = "light.${light}_light";
              brightness = "{{ trigger.payload_json.brightness }}";
            };
          }
        ];
      }
      {
        alias = "lightswitch ${switch} turn off light ${light}";
        hide_entity = "true";
        trigger = {
          platform = "mqtt";
          topic = "zigbee/${switch}";
        };
        condition = {
          condition = "or";
          conditions = [
            {
              condition = "template";
              value_template = "{{ trigger.payload_json.action == 'off-press' }}";
            }
            {
              condition = "template";
              value_template = "{{ trigger.payload_json.brightness < 30 }}";
            }
          ];
        };
        action = {
          service = "light.turn_off";
          data_template = {
            entity_id = "light.${light}_light";
          };
        };
      }
    ];
  };
}
