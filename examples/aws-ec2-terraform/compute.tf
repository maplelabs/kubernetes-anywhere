resource "aws_launch_configuration" "kubernetes-node-group" {
    name                        = "kubernetes-node-group"
    image_id                    = "ami-33566d03"
    instance_type               = "t2.micro"
    iam_instance_profile        = "${aws_iam_instance_profile.kubernetes-node.name}"
    ebs_optimized               = false
    enable_monitoring           = true
    key_name                    = "terraform"
    security_groups             = ["${aws_security_group.kubernetes-node.id}"]
    associate_public_ip_address = true
    user_data                   = "${file("user-data.yaml")}"

    root_block_device {
        volume_type           = "gp2"
        volume_size           = 32
        delete_on_termination = true
    }
}

resource "aws_autoscaling_group" "kubernetes-node-group" {
    desired_capacity          = 3
    health_check_grace_period = 0
    health_check_type         = "EC2"
    launch_configuration      = "${aws_launch_configuration.kubernetes-node-group.name}"
    max_size                  = 3
    min_size                  = 3
    name                      = "kubernetes-node-group"
    vpc_zone_identifier       = ["${aws_subnet.kubernetes-subnet.id}"]

    tag {
        key   = "KubernetesCluster"
        value = "kubernetes"
        propagate_at_launch = true
    }

    tag {
        key   = "Name"
        value = "kubernetes-node"
        propagate_at_launch = true
    }
}

resource "aws_instance" "kubernetes-master" {
    ami                         = "ami-33566d03"
    ebs_optimized               = false
    instance_type               = "t2.micro"
    monitoring                  = false
    key_name                    = "terraform"
    subnet_id                   = "${aws_subnet.kubernetes-subnet.id}"
    vpc_security_group_ids      = ["${aws_security_group.kubernetes-master.id}"]
    associate_public_ip_address = true
    #private_ip                  = "172.20.0.9"
    source_dest_check           = true
    iam_instance_profile        = "${aws_iam_instance_profile.kubernetes-master.name}"
    user_data                   = "${file("user-data.yaml")}"

    ebs_block_device {
        device_name           = "/dev/sdb"
        snapshot_id           = ""
        volume_type           = "gp2"
        volume_size           = 20
        delete_on_termination = false
    }

    root_block_device {
        volume_type           = "gp2"
        volume_size           = 8
        delete_on_termination = true
    }

    tags {
        "KubernetesCluster" = "kubernetes"
        "Name" = "kubernetes-master"
    }
}

resource "aws_instance" "kubernetes-etcd" {
    count                       = 3
    ami                         = "ami-33566d03"
    ebs_optimized               = false
    instance_type               = "t2.micro"
    monitoring                  = false
    key_name                    = "terraform"
    subnet_id                   = "${aws_subnet.kubernetes-subnet.id}"
    vpc_security_group_ids      = ["${aws_security_group.kubernetes-master.id}"]
    associate_public_ip_address = true
    source_dest_check           = true
    iam_instance_profile        = "${aws_iam_instance_profile.kubernetes-master.name}"
    user_data                   = "${file("user-data.yaml")}"

    ebs_block_device {
        device_name           = "/dev/sdb"
        snapshot_id           = ""
        volume_type           = "gp2"
        volume_size           = 20
        delete_on_termination = false
    }

    root_block_device {
        volume_type           = "gp2"
        volume_size           = 8
        delete_on_termination = true
    }

    tags {
        "KubernetesCluster" = "kubernetes"
        "Name" = "kubernetes-etcd"
        "KubernetesEtcdNodeName" = "etcd${count.index + 1}"
    }
}