variable "subscription_id" {
  type = string
}

variable "rsc_location" {
  type    = string
  default = "japaneast"
}

variable "rsc_prefix" {
  type = string
}

variable "vnet_address_space" {
  type = string
}

variable "cnt_info" {
  type = object({
    ercct_id = string
    cnt_key  = string
  })
}

variable "admin_info" {
  type = object({
    user_name = string
    password  = string
  })
}
