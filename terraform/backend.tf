terraform {
  cloud {
    organization = "YOUR_ORG_NAME"
    
    workspaces {
      name = "bedrock-chat-test"
    }
  }
}
