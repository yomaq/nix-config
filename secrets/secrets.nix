let
  agenix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOkt8xgN5ZlTyuSBWAhlv0CCxIN6LmzfSMTHTc53rZ6i";
  carln = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICEYoH0dcCQP4sFB3Jl3my7tqXdcwvHo0mOdDdB39UFX";
  green = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGDIHB7suLTRA3Ao/KZmcyCe5ojYAQ72EYoCbkdqlROT";
  blue = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK/3xL59H/gxyf/zNwM9d0KlovD3GfSGHKgCbmloiGCR";
  azure = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP1N/rg1O+vUNIaOVgTJcyB95fufM2PQPEZRso1OlaSu";

  # keys to work for all secrets
  all = [ agenix carln blue ];

in
{
  "carln.age".publicKeys = [ green ] ++ all;
  "encrypt.age".publicKeys = all;
  "tailscaleKey.age".publicKeys = [ green azure ] ++ all;
  "tailscaleEnvFile.age".publicKeys = [ green ] ++ all;
  "piholeEnvFile.age".publicKeys = [ green ] ++ all;

  #example for calling groups
  #"secret2.age".publicKeys = users ++ systems;
}