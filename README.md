# Azure AD - AWS IAM Identity Center (SSO + SCIM) Integration

Provisions end-to-end integration between **Azure Active Directory (Microsoft Entra)** and **AWS IAM Identity Center** with:

- **SCIM provisioning**: Users and groups sync automatically from Azure AD to AWS
- **SAML SSO**: Federated authentication
- **Flexible permission sets**: Managed policies, inline policies, permissions boundaries
- **Group-based access**: Define groups with members, assign to AWS accounts

## Quick Start

### 1. Enable SCIM in AWS

1. Go to **AWS IAM Identity Center** → **Settings** → **Identity source**
2. Click **Actions** → **Change identity source** → **External identity provider**
3. Enable **Automatic provisioning** and copy:
   - SCIM endpoint URL
   - Access token (save immediately, shown only once)
4. Copy SAML values:
   - IAM Identity Center Issuer URL (entity ID)
   - IAM Identity Center ACS URL

### 2. Configure terraform.tfvars

```hcl
# AWS SSO Configuration
aws_saml_entity_id = "https://us-east-1.signin.aws.amazon.com/platform/saml/d-xxxxxxxxxx"
aws_saml_acs       = "https://us-east-1.signin.aws.amazon.com/platform/saml/acs/xxxxxxxx"
aws_sso_loging_url = "https://d-xxxxxxxxxx.awsapps.com/start"

# Users - key IS the email address
identity_users = {
  "john.smith@company.com" = {
    display_name       = "John Smith"
    given_name         = "John"
    surname            = "Smith"
    azure_ad_user_type = "Member"
  }
  "jane.doe@external.com" = {
    display_name       = "Jane Doe"
    given_name         = "Jane"
    surname            = "Doe"
    azure_ad_user_type = "Guest"
  }
}

# Groups with members
identity_groups = {
  admins = {
    description = "Administrators"
    members     = ["john.smith@company.com"]
  }
  developers = {
    description = "Development team"
    members     = ["john.smith@company.com", "jane.doe@external.com"]
  }
}

# Permission sets
permission_sets = {
  administrator = {
    description      = "Full admin access"
    session_duration = "PT4H"
    managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
  }
  developer = {
    description      = "Developer access"
    managed_policies = [
      "arn:aws:iam::aws:policy/PowerUserAccess",
      "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
    ]
  }
}

# Assign groups to permission sets per account
group_permission_assignments = [
  {
    group          = "admins"
    permission_set = "administrator"
    account_id     = "111111111111"
  },
  {
    group          = "developers"
    permission_set = "developer"
    account_id     = "222222222222"
  }
]
```

### 3. Deploy Azure AD Resources

```bash
terraform init
terraform apply -target=module.azuread_sso_app
```

### 4. Configure SCIM in Azure Portal

1. **Enterprise Applications** → your app → **Provisioning**
2. Set mode to **Automatic**
3. Enter AWS SCIM endpoint and token
4. Verify attribute mappings include:
   - `givenName` → `name.givenName`
   - `surname` → `name.familyName`
5. **Start provisioning**

### 5. Complete Deployment

Once SCIM sync completes:

```bash
terraform apply
```

### 6. Upload SAML Metadata

1. Azure AD → Enterprise App → **Single sign-on** → Download Federation Metadata XML
2. AWS IAM Identity Center → Upload the metadata

---

## Configuration Reference

### Users

The map key is the user's email address (used as `user_principal_name`):

```hcl
identity_users = {
  "email@domain.com" = {
    display_name       = "Full Name"
    given_name         = "First"
    surname            = "Last"
    azure_ad_user_type = "Member"  # or "Guest"
  }
}
```

- **Member**: Created in directory with generated password
- **Guest**: Invited via email

### Groups

Groups define their members directly:

```hcl
identity_groups = {
  group_name = {
    description = "Group description"
    members     = ["user1@email.com", "user2@email.com"]
  }
}
```

### Permission Sets

Flexible permission configuration:

```hcl
permission_sets = {
  my_permission_set = {
    description      = "Description"
    session_duration = "PT8H"  # ISO 8601 duration
    
    # Option 1: AWS managed policies
    managed_policies = [
      "arn:aws:iam::aws:policy/ReadOnlyAccess"
    ]
    
    # Option 2: Inline policy (JSON)
    inline_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "*"
      }]
    })
    
    # Option 3: Permissions boundary
    permissions_boundary = "arn:aws:iam::aws:policy/PowerUserAccess"
  }
}
```

### Group Permission Assignments

Assign groups to permission sets for specific AWS accounts:

```hcl
group_permission_assignments = [
  {
    group          = "group_name"
    permission_set = "permission_set_name"
    account_id     = "123456789012"
  }
]
```

---

## Typical Permission Sets

| Permission Set | Use Case | Policies |
|---------------|----------|----------|
| `administrator` | Full access | AdministratorAccess |
| `power_user` | Everything except IAM | PowerUserAccess |
| `developer` | Dev resources | Lambda, S3, DynamoDB, CloudWatch |
| `data_engineer` | Analytics/ML | S3, Athena, Glue, Redshift, SageMaker |
| `security_auditor` | Security review | SecurityAudit, CloudTrail, GuardDuty |
| `read_only` | View only | ReadOnlyAccess |
| `billing` | Cost management | BillingReadOnly |

See `terraform.tfvars.example` for complete examples.

---

## Architecture

```
┌─────────────────┐         SCIM Sync          ┌──────────────────────┐
│    Azure AD     │ ─────────────────────────> │  AWS IAM Identity    │
│                 │     (Users & Groups)       │      Center          │
│  - Users        │                            │                      │
│  - Groups       │         SAML SSO           │  - Users (synced)    │
│  - Enterprise   │ <────────────────────────> │  - Groups (synced)   │
│    Application  │     (Authentication)       │  - Permission Sets   │
└─────────────────┘                            └──────────────────────┘
```

## Prerequisites

- Azure AD tenant with admin access
- AWS IAM Identity Center enabled
- Terraform 1.3+
- Azure CLI authenticated (`az login`)
- AWS CLI authenticated
