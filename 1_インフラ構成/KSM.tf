//カスタマーマスターキー
resource "aws_kms_key" "example" {
    description = "Example Customer Master Key"
    enable_key_rotation = true
    is_enabled = true
    //削除待機期間
    //ちなみにカスタマーキーを消すとまじでデータの復号ができなくなるから通常は↑の設定の無効化を選択するらしい
    deletion_window_in_days = 30
}

//エイリアス
//カスタマー期にはそれぞれUUIDが割り当てられるけど分かりづらいからエイリアスというのが別途必要
resource "aws_kms_alias" "example" {
    //!名前の戦闘はalias/にしなきゃいけない謎制約
    name = "alias/example"
    target_key_id = aws_kms_key.example.key_id
}