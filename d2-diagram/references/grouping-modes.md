# Grouping Modes

## `resource-group` (default)

Wrap all resources inside D2 containers matching their Azure Resource Group.
Cross-container links use dot notation (`rg-common.key-vault`).

```d2
rg-common: "Resource Group — Common" {
  style: { fill: "#F0F0F0"; stroke: "#999999"; border-radius: 8 }

  vnet: "Virtual Network" { ... }
  snet-pe: "snet-pe" { ... }
  key-vault: "Key Vault" { ... }
}

rg-app: "Resource Group — App" {
  style: { fill: "#F5F9FF"; stroke: "#B0C4DE"; border-radius: 8 }

  web-app: "Web App" { ... }
  cosmos-db: "Cosmos DB" { ... }
}

rg-app.web-app -> rg-common.key-vault: "reads secrets" { ... }
```

### Warning: Always use full dot-notation paths in connections

When resources are declared inside containers, **all connection endpoints must use the full dot-notation path** (`container.node`). Using a bare node name creates a new top-level ghost node instead of referencing the existing nested one — the diagram renders without error but contains duplicate orphan nodes outside the resource group containers.

```d2
# ❌ Wrong — D2 silently creates new top-level nodes named subnet_pe and pe_kv
subnet_pe -> pe_kv: "subnet" { class: pe-link }

# ✅ Correct — references the existing nodes inside rg_common
rg_common.subnet_pe -> rg_common.pe_kv: "subnet" { class: pe-link }

# ✅ Correct — cross-container connection
rg_common.subnet_pe -> rg_todo.pe_cosmos: "subnet" { class: pe-link }
```

### Rule: No subscription-level wrapper for single-subscription diagrams

For single-subscription deployments the top-level grouping is the **resource group**. Do not add a subscription-level container unless the diagram explicitly covers multiple subscriptions.

Adding a subscription wrapper around RGs introduces a third nesting level with no visual benefit, forces three-segment paths on every connection (`subscription.rg_common.pe_kv`), and constrains the ELK layout engine with an extra bounding box.

```d2
# ❌ Avoid for single-subscription
subscription: "Subscription\n..." {
  rg_common: "RG — common" { ... }
  rg_app: "RG — app" { ... }
}

# ✅ Correct — RGs at the top level
rg_common: "RG — common" { ... }
rg_app: "RG — app" { ... }
```

## `vnet-centric`

Wrap **only network resources** inside VNet containers. Non-network resources
are top-level nodes that connect into VNet containers via links.

**Resources inside VNet containers:**
- `azurerm_virtual_network` (the container itself)
- `azurerm_subnet`
- `azurerm_network_security_group` (+ association)
- `azurerm_private_endpoint`
- `azurerm_public_ip`
- `azurerm_nat_gateway` (+ subnet association)
- `azurerm_route_table`
- `azurerm_network_interface`

**Resources outside VNet containers (top-level):**
- All compute: web apps, function apps, VMs, AKS, container apps
- All data: Cosmos DB, SQL, Storage
- All shared services: Key Vault, App Configuration, Log Analytics
- All monitoring: Application Insights
- Service Plans
- Internet node

**VNet peerings** are placed **between** VNet containers, never inside:

```d2
vnet-hub: "VNet Hub\n10.0.0.0/16" {
  style: { fill: "#E8F0FE"; stroke: "#0D3B66"; border-radius: 8 }

  snet-pe: "snet-pe" { ... }
  snet-app: "snet-app" { ... }
  nsg-runner: "NSG Runner" { ... }
  pe-kv: "PE Key Vault" { ... }
}

vnet-spoke: "VNet Spoke\n10.1.0.0/16" {
  style: { fill: "#E8F0FE"; stroke: "#0D3B66"; border-radius: 8 }

  snet-workload: "snet-workload" { ... }
}

# Peering — outside both VNet containers
vnet-hub <-> vnet-spoke: "VNet peering" {
  style: {
    stroke: "#0D3B66"
    stroke-width: 3
    stroke-dash: 3
  }
}

# Non-network resources at top level
web-app: "Web App" { ... }
key-vault: "Key Vault" { ... }
cosmos-db: "Cosmos DB" { ... }

# Links go into VNet containers
web-app -> vnet-hub.snet-app: "VNet integration" { class: vnet-integration }
vnet-hub.pe-kv -> key-vault: "private-link: vault" { class: pe-resource-link }
```

**VNet container style:**
```d2
style: {
  fill: "#E8F0FE"
  stroke: "#0D3B66"
  border-radius: 8
}
```

## `flat`

No containers — every resource is a top-level node. All links are direct
(no dot notation). Simplest layout, best for small infra or quick overviews.

```d2
vnet: "Virtual Network" { ... }
snet-pe: "snet-pe" { ... }
web-app: "Web App" { ... }
key-vault: "Key Vault" { ... }

vnet -> snet-pe: "" { class: network-link }
web-app -> snet-pe: "VNet integration" { class: vnet-integration }
```
