<?php
include 'config1.php';

// السماح بطلبات CORS
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// الحصول على البيانات كـ JSON
$data = json_decode(file_get_contents("php://input"));

// التحقق من وجود البيانات
if(empty($data->username) || empty($data->password)) {
    http_response_code(400);
    echo json_encode(array("message" => "اسم المستخدم وكلمة المرور مطلوبان"));
    exit();
}

// البحث عن المستخدم
$query = "SELECT username, password FROM users WHERE username = :username";
$stmt = $conn->prepare($query);
$stmt->bindParam(':username', $data->username);
$stmt->execute();

if($stmt->rowCount() == 0) {
    http_response_code(401);
    echo json_encode(array("message" => "اسم المستخدم غير صحيح"));
    exit();
}

$row = $stmt->fetch(PDO::FETCH_ASSOC);

// مقارنة كلمة المرور
if($data->password === $row['password']) {
    http_response_code(200);
    echo json_encode(array(
        "message" => "تم تسجيل الدخول بنجاح",
        "user" => array(
            "username" => $row['username']
        )
    ));
} else {
    http_response_code(401);
    echo json_encode(array("message" => "كلمة المرور غير صحيحة"));
}
?>