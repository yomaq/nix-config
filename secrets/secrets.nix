let
  agenix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOkt8xgN5ZlTyuSBWAhlv0CCxIN6LmzfSMTHTc53rZ6i";
  carln = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDF1TFwXbqdC1UyG75q3HO1n7/L3yxpeRLIq2kQ9DalI";
  green = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJOKOvSM5ibLkiVi+0hmt3eWlmTprMIqtYzkHgKdSVsq";
  moss = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHUFH+p2RqZ4g1Gec7UZWyr390wketZRCtp93bNAyzZ7";
  jade = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFzLi/rhHVmk8op1uTZk4Vzhk/yvzQKv2CYNHxEy/7Ak";
  azure = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP1N/rg1O+vUNIaOVgTJcyB95fufM2PQPEZRso1OlaSu";
  teal = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIQQRdx0vygfX8LZFLq2Dg8X3EGYLIB+hL788x7LP+29";
  smalt = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPsEPoDzF3MRUY0adefhlXkHoErrLncXrV1GTXbM8Znt";
  wsl = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEVvSvIGRCpR3vo0QTeFPFb6vlatnQkqKhbN4m3H2DKn";

  # keys to work for all secrets
  all = [
    agenix
    carln
  ];

in
{
  "carln.age".publicKeys = [ green ] ++ all;
  "admin.age".publicKeys = [
    azure
    smalt
    teal
    moss
    jade
  ] ++ all;
  "ryn.age".publicKeys =  all;
  "encrypt.age".publicKeys = all;
  "tailscaleKey.age".publicKeys = [
    green
    moss
    jade
    azure
    teal
    smalt
    wsl
  ] ++ all;
  "tailscaleOAuthKeyAcceptSsh.age".publicKeys = [
    green
    moss
    jade
    azure
    teal
    smalt
    wsl
  ] ++ all;
  "tailscaleEnvFile.age".publicKeys = [
    green
    moss
    jade
    azure
    teal
    smalt
    wsl
  ] ++ all;
  "tailscaleOAuthEnvFile.age".publicKeys = [
    green
    moss
    jade
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
