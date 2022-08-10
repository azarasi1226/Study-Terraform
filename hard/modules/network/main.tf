
// VPC作成
resource "aws_vpc" "example" {
  cidr_block = "192.168.0.0/16"

  //DNSサーバーによる名前解決を有効にし、自動でDNSホスト名を割与える
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    // 一部のAWSリソースはNameタグがないとマネジメントコンソール一覧で表示名がなくて分かりづらくなる
    Name = "example-vpc"
  }
}

//インターネットゲートウェイ
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "example-igw"
  }
}

//パブリックサブネット1
resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = "ap-northeast-1a"

  //サブネット内で起動したインスタンスにパブリックIPを自動的に割り当ててくれる機能
  //これがないと外部からアクセスできなくなる。これをonにすることでパブリックサブネットってことになるんやな！
  map_public_ip_on_launch = true

  tags = {
    Name = "example-public-subnet01"
  }
}

//パブリックサブネット1
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "192.168.2.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "example-public-subnet02"
  }
}

//ルートテーブル
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "example-public-route-table"
  }
}

//内部からインターネットに通信するルート
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.example.id
  destination_cidr_block = "0.0.0.0/0"
}

//ルートテーブルをサブネット1に紐づける
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

//ルートテーブルをサブネット2に紐づける
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}


//----------------------------------private-------------------------------------


//プライベートサブネット1
resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "192.168.101.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "example-private-subnet01"
  }
}

//プライベートサブネット2
resource "aws_subnet" "private_2" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "192.168.102.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "example-private-subnet02"
  }
}

//プライベートルートテーブル1
resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "example-private-route-table01"
  }
}

//プライベートルートテーブル2
// 0.0.0.0/0通信は１テーブルにつき１個しか定義できない。まぁよくよく考えたら当然
// 0.0.0.0/→nat-gateway01 と 0.0.0.0/→natgetway-2が同じテーブルにあったらどっちに分岐していいかわからんもんね
resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "example-private-route-table02"
  }
}

//プライベートルートテーブル1をプライベートサブネット1に紐づけ
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

//プライベートルートテーブル2をプライベートサブネット2に紐づけ
resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_2.id
}

//EIP1
resource "aws_eip" "nat_gateway_1" {
  vpc = true

  // EIP では、関連付けの前に IGW が存在する必要がある場合があります。depends_onIGW に明示的な依存関係を設定するために使用します。
  depends_on = [
    aws_internet_gateway.example
  ]
  tags = {
    Name = "example-eip-01"
  }
}

//EIP2
resource "aws_eip" "nat_gateway_2" {
  vpc = true

  // EIP では、関連付けの前に IGW が存在する必要がある場合があります。depends_onIGW に明示的な依存関係を設定するために使用します。
  depends_on = [
    aws_internet_gateway.example
  ]
  tags = {
    Name = "example-eip-02"
  }
}

//nat-gateway1
resource "aws_nat_gateway" "example_1" {
  allocation_id = aws_eip.nat_gateway_1.id
  subnet_id     = aws_subnet.public_1.id

  depends_on = [
    aws_internet_gateway.example
  ]
  tags = {
    Name = "example-nategateway-01"
  }
}

//nat-gateway2
resource "aws_nat_gateway" "example_2" {
  allocation_id = aws_eip.nat_gateway_2.id
  subnet_id     = aws_subnet.public_2.id

  depends_on = [
    aws_internet_gateway.example
  ]
  tags = {
    Name = "example-nategateway-02"
  }
}

//プライベートのルート1定義
resource "aws_route" "private_1" {
  route_table_id         = aws_route_table.private_1.id
  nat_gateway_id         = aws_nat_gateway.example_1.id
  destination_cidr_block = "0.0.0.0/0"
}

//プライベートのルート2定義
resource "aws_route" "private_2" {
  route_table_id         = aws_route_table.private_2.id
  nat_gateway_id         = aws_nat_gateway.example_2.id
  destination_cidr_block = "0.0.0.0/0"
}


//--------------------セキュリティグループ------------------
resource "aws_security_group" "example" {
  name   = "example"
  vpc_id = aws_vpc.example.id
}

// インバウンドルール(ウェブサイトの閲覧OK)
resource "aws_security_group_rule" "ingress_example" {
  type              = "ingress"
  from_port         = "80"
  to_port           = "80"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.example.id
}

// アウトバウンドルール(すべての通信OK)
resource "aws_security_group_rule" "egress_example" {
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.example.id
}

