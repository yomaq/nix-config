let
  agenix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOkt8xgN5ZlTyuSBWAhlv0CCxIN6LmzfSMTHTc53rZ6i";
  carln = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICEYoH0dcCQP4sFB3Jl3my7tqXdcwvHo0mOdDdB39UFX";
  green = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA+JAQVPpnno4PNYWSoTIbpNTkJ8EZDPobKFv0oL7tpu";

  #example for making groups
  #users = [ user1 user2 ];

in
{
  "carln.age".publicKeys = [ agenix carln ];
  "encrypt.age".publicKeys = [ agenix carln ];
  "tailscaleKey.age".publicKeys = [ agenix carln green];

  #example for calling groups
  #"secret2.age".publicKeys = users ++ systems;
}