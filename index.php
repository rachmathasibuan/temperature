<?php
$conn = new mysqli(
    "10.157.0.164",
    "leonor",
    "805@leonor",
    "temp",
    33061
);

if ($conn->connect_error) {
    die("Database connection failed");
}

$sql = "
    SELECT id, temp, hum, event
    FROM data
    ORDER BY id DESC
    LIMIT 20
";

$result = $conn->query($sql);
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Sensor Monitor</title>
<style>
    body {
        font-family: Arial, sans-serif;
        background: #f4f6f8;
        padding: 40px;
    }
    h2 {
        margin-bottom: 20px;
        color: #333;
    }
    table {
        width: 100%;
        border-collapse: collapse;
        background: #fff;
        box-shadow: 0 4px 10px rgba(0,0,0,0.05);
    }
    th, td {
        padding: 12px 15px;
        text-align: center;
    }
    th {
        background: #2f80ed;
        color: #fff;
        font-weight: normal;
    }
    tr:nth-child(even) {
        background: #f9f9f9;
    }
    .event {
        font-weight: bold;
        color: #27ae60;
    }
</style>
</head>
<body>

<h2>📊 Sensor Temperature & Humidity</h2>

<table>
    <tr>
        <th>ID</th>
        <th>Temperature (°C)</th>
        <th>Humidity (%)</th>
        <th>Event</th>
    </tr>

    <?php if ($result && $result->num_rows > 0): ?>
        <?php while ($row = $result->fetch_assoc()): ?>
            <tr>
                <td><?= $row['id'] ?></td>
                <td><?= $row['temp'] ?></td>
                <td><?= $row['hum'] ?></td>
                <td class="event"><?= $row['event'] ?? '-' ?></td>
            </tr>
        <?php endwhile; ?>
    <?php else: ?>
        <tr>
            <td colspan="4">No data available</td>
        </tr>
    <?php endif; ?>

</table>

</body>
</html>

<?php $conn->close(); ?>
