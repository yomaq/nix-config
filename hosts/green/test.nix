{ config
, pkgs
, lib
, ...
}:
{
  config.yomaq.homepage.settings ={
      title = "{{HOMEPAGE_VAR_NAME}}";
      background = {
          blur = "sm"; # sm, "", md, xl... see https://tailwindcss.com/docs/backdrop-blur
          saturate = 50; # 0, 50, 100... see https://tailwindcss.com/docs/backdrop-saturate
          brightness = 50; # 0, 50, 75... see https://tailwindcss.com/docs/backdrop-brightness
          opacity = 50; # 0-100
      };
      theme = "dark"; # or light
      providers = {
          openweathermap = "openweathermapapikey";
          weatherapi = "weatherapiapikey";
      };
    };
}