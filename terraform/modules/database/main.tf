resource "aws_dynamodb_table" "conversation" {
  name         = "${var.env_prefix}BedrockChatConversation"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }
  attribute {
    name = "SK"
    type = "S"
  }

  # GSI: SKIndex - Used to fetch conversation or bot by id
  global_secondary_index {
    name            = "SKIndex"
    hash_key        = "SK"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"
}

resource "aws_dynamodb_table" "bot" {
  name         = "${var.env_prefix}BedrockChatBot"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }
  attribute {
    name = "SK"
    type = "S"
  }
  attribute {
    name = "BotId"
    type = "S"
  }
  attribute {
    name = "SharedScope"
    type = "S"
  }
  attribute {
    name = "SharedStatus"
    type = "S"
  }
  attribute {
    name = "ItemType"
    type = "S"
  }
  attribute {
    name = "IsStarred"
    type = "S"
  }
  attribute {
    name = "LastUsedTime"
    type = "N"
  }

  # GSI-1: BotIdIndex
  global_secondary_index {
    name            = "BotIdIndex"
    hash_key        = "BotId"
    projection_type = "ALL"
  }

  # GSI-2: SharedScopeIndex
  global_secondary_index {
    name            = "SharedScopeIndex"
    hash_key        = "SharedScope"
    range_key       = "SharedStatus"
    projection_type = "ALL"
  }

  # GSI-3: ItemTypeIndex
  global_secondary_index {
    name            = "ItemTypeIndex"
    hash_key        = "ItemType"
    projection_type = "ALL"
  }

  # LSI-1: StarredIndex
  local_secondary_index {
    name            = "StarredIndex"
    range_key       = "IsStarred"
    projection_type = "ALL"
  }

  # LSI-2: LastUsedTimeIndex
  local_secondary_index {
    name            = "LastUsedTimeIndex"
    range_key       = "LastUsedTime"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"
}

resource "aws_dynamodb_table" "websocket_session" {
  name         = "${var.env_prefix}BedrockChatWebSocketSession"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ConnectionId"
  range_key    = "MessagePartId"

  attribute {
    name = "ConnectionId"
    type = "S"
  }
  attribute {
    name = "MessagePartId"
    type = "N"
  }

  ttl {
    attribute_name = "expire"
    enabled        = true
  }
}
