<h2>Check that domains can be accessed</h2>
<ul>
    <li>
        <a href="http://minimal.puppet-lamp.dev">minimal</a>
    </li>
    <li>
        <a href="http://full.puppet-lamp.dev/">full</a>
        - Directory Index should be enabled
    </li>
    <li>
        <a href="http://alias.puppet-lamp.dev/tests.php">alias</a>
    </li>
    <li>
        <a href="https://ssl1.puppet-lamp.dev/tests.php">ssl-1</a>
    </li>
    <li>
        <a href="https://ssl2.puppet-lamp.dev/tests.php">ssl-2</a>
    </li>
</ul>

<h2>Connect to database</h2>
<?php
  try {
    $dbh = new PDO('mysql:host=localhost;dbname=full', 'full', 'password');
    echo 'Connection successful!';
  } catch (PDOException $e) {
    echo 'Connection failed: ' . $e->getMessage();
  }
?>

<h2>System user creation</h2>
<b>Home Dir</b>
<br>
<?php
  if (file_exists('/home/full')) {
    echo "Successful";
  } else {
    echo "Fail. /home/full does not exist";
  }
?>
<br>
<b>User</b>
<br>
<?php
  if (exec('grep "^full:" /etc/passwd')) {
    echo "Successful";
  } else {
    echo "Fail. User \"full\" does not exist";
  }
?>
