# Drop the pairing token from lines the hub prints to stdout.
# The two shapes are in src/server/server.bend (Tailnet.listened, Tailnet.https)
# and src/core/tailnet.bend (Tailnet.link): "pairing token <hex>" and
# "<url>/#token=<hex>". The URL itself stays.
{
  gsub(/pairing token [^ )]+/, "pairing token (see the token file)")
  gsub(/#token=[^[:space:]]+/, "#token=(see the token file)")
  print
  fflush()
}
