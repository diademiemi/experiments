data "digitalocean_domain" "domain" {
  for_each = {
    for record in var.dns_records : record.name => record
    if record.domain != null && record.domain != ""
  }
  name = each.value.domain
}

data "digitalocean_domain" "default_domain" {
  count = var.digitalocean_default_domain != "" ? 1 : 0
  name = var.digitalocean_default_domain
}

resource "digitalocean_record" "records" {
  for_each = {
    for record in var.dns_records : record.name => record
  }

  domain  = coalesce(each.value.domain_id, try(data.digitalocean_domain.domain[each.key].id, ""), try(data.digitalocean_domain.default_domain[0].id, ""), var.digitalocean_default_domain_id)
  type    = coalesce(each.value.type, var.digitalocean_default_type)
  name    = each.value.name
  value   = each.value.value
  ttl     = coalesce(each.value.ttl, var.digitalocean_default_ttl) # DO provider uses seconds
}