let
  agenix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOkt8xgN5ZlTyuSBWAhlv0CCxIN6LmzfSMTHTc53rZ6i";
  carln = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDF1TFwXbqdC1UyG75q3HO1n7/L3yxpeRLIq2kQ9DalI";
  green = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC6SpXx+KkF50yMmAKKX2gY6hacxEQK+5ofcucb3OkOF";
  blue = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK/3xL59H/gxyf/zNwM9d0KlovD3GfSGHKgCbmloiGCR";
  azure = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP1N/rg1O+vUNIaOVgTJcyB95fufM2PQPEZRso1OlaSu";
  teal = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIQQRdx0vygfX8LZFLq2Dg8X3EGYLIB+hL788x7LP+29";
  smalt = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPsEPoDzF3MRUY0adefhlXkHoErrLncXrV1GTXbM8Znt";
  wsl = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHHfIh3ZM2gFaWnkuv52+ez18Qn0PqNlOF14f12N6whS";

  # keys to work for all secrets
  all = [
    agenix
    carln
    blue
  ];

in
{
  "carln.age".publicKeys = [ green ] ++ all;
  "ryn.age".publicKeys = [ blue ] ++ all;
  "encrypt.age".publicKeys = all;
  "tailscaleKey.age".publicKeys = [
    green
    azure
    teal
    smalt
    wsl
  ] ++ all;
  "tailscaleOAuthKeyAcceptSsh.age".publicKeys = [
    green
    azure
    teal
    smalt
    wsl
  ] ++ all;
  "tailscaleEnvFile.age".publicKeys = [
    green
    azure
    teal
    smalt
    wsl
  ] ++ all;
  "tailscaleOAuthEnvFile.age".publicKeys = [
    green
    azure
    teal
    smalt
    wsl
  ] ++ all;
  "piholeEnvFile.age".publicKeys = [ green ] ++ all;
  "nextcloudEnvFile.age".publicKeys = [
    azure
    green
  ] ++ all;
  "nextcloudDBEnvFile.age".publicKeys = [
    azure
    green
  ] ++ all;
  "palworldEnvFile.age".publicKeys = [
    teal
    smalt
  ] ++ all;
  "teslamateEnvFile.age".publicKeys = [
    teal
    azure
  ] ++ all;
  "teslamateDBEnvFile.age".publicKeys = [
    teal
    azure
  ] ++ all;
  "teslamateGrafanaEnvFile.age".publicKeys = [
    teal
    azure
  ] ++ all;
  "semaphoreEnvFile.age".publicKeys = [
    teal
    azure
  ] ++ all;
  "semaphoreDBEnvFile.age".publicKeys = [
    teal
    azure
  ] ++ all;
  "homepage.age".publicKeys = [ azure ] ++ all;
  "linkwardenEnvFile.age".publicKeys = [
    teal
    azure
  ] ++ all;
  "linkwardenDBEnvFile.age".publicKeys = [
    teal
    azure
  ] ++ all;
  "healthchecks.age".publicKeys = [ azure ] ++ all;

  #example for calling groups
  #"secret2.age".publicKeys = users ++ systems;
}
