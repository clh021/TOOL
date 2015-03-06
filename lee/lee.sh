#!/bin/bash

# ln -s /etc/php5 /home/lee/clh/links/etc.php5
# ln -s /etc/apache2 /home/lee/clh/links/etc.apache2
# ln -s /etc/mysql /home/lee/clh/links/etc.mysql

# path /etc/apache2/apache2.conf
# from "User ${APACHE_RUN_USER}" to "User lee"
# from "Group ${APACHE_RUN_GROUP}" to "Group lee"
# from "<Directory /var/www/>" to "<Directory /home/lee/clh/www/>"


#phpcs --standard=Symfony2 -n src/Deepin/DeepinID/UserBundle/
#phpunit -c app/ src/Deepin/DeepinID/UserBundle/Tests/

#备份
#sudo tar -czf ~/lc.data$(date +%Y%m%d_%H%M%S).tar.gz /etc/hosts /etc/apache2/ /etc/php5/ /etc/mysql/ /var/www/ /usr/local/bin/ /home/lee/workspace/ /home/lee/LSF/ /home/lee/.fonts/ /home/lee/.filezilla/ /home/lee/.ssh/ /home/lee/.remmina/ /home/lee/.config/sublime-text-2/ /var/cache/apt/archives/
#恢复
#解压相关archives到/var/cache/apt/archives
#软链接到自己的archives

sudo apt-get update
sudo apt-get dist-upgrade
sudo apt-get install mysql-server mysql-client apache2 php5 php5-mysql php5-mcrypt php5-curl php5-gd

#软链接几个配置目录和数据目录到自己的配置及数据
mv ~/.ssh ~/.ssh$(date +%Y%m%d_%H%M%S)_bak
sudo ln -s ~/clh/config/.ssh ~/.ssh
sudo cp -r ~/.mozilla ~/clh/config/.mozilla$(date +%Y%m%d_%H%M%S)_bak
mv ~/.mozilla ~/.mozilla$(date +%Y%m%d_%H%M%S)_bak
sudo ln -s ~/clh/config/.mozilla ~/.mozilla
sudo cp -r ~/.fonts ~/clh/config/.fonts$(date +%Y%m%d_%H%M%S)_bak
mv ~/.fonts ~/.fonts$(date +%Y%m%d_%H%M%S)_bak
sudo ln -s ~/clh/config/.fonts ~/.fonts

sudo cp -r /etc/hosts ~/clh/config/hosts$(date +%Y%m%d_%H%M%S)_bak
sudo mv /etc/hosts /etc/hosts$(date +%Y%m%d_%H%M%S)_bak
sudo ln -s ~/clh/config/hosts /etc/hosts

#apache2
sudo /etc/init.d/apache2 stop
sudo cp -r /etc/apache2 ~/clh/config/apache2$(date +%Y%m%d_%H%M%S)_bak
sudo mv /etc/apache2 /etc/apache2$(date +%Y%m%d_%H%M%S)_bak
sudo ln -s ~/clh/config/apache2 /etc/apache2

sudo cp -r /etc/php5 ~/clh/config/php5$(date +%Y%m%d_%H%M%S)_bak #php5
sudo mv /etc/php5 /etc/php5$(date +%Y%m%d_%H%M%S)_bak #php5
sudo ln -s ~/clh/config/php5 /etc/php5 #php5

#sudo service nginx stop
#sudo cp -r /etc/nginx ~/clh/config/nginx_bak$(date +%Y%m%d_%H%M%S) #nginx
#sudo mv /etc/nginx #nginx
#sudo ln -s ~/clh/config/nginx /etc/nginx #nginx
#sudo service nginx start

sudo mv /var/www/html /var/www/html$(date +%Y%m%d_%H%M%S)_bak #www
sudo ln -s ~/clh/www /var/www/html #www

sudo /etc/init.d/apache2 start



# #mysql
# sudo stop mysql
# sudo cp -r /etc/mysql ~/clh/config/mysql$(date +%Y%m%d_%H%M%S)_bak
# sudo mv /etc/mysql /etc/mysql$(date +%Y%m%d_%H%M%S)_bak
# sudo ln -s ~/clh/config/mysql /etc/mysql
# sudo cp -r /var/lib/mysql ~/clh/db/mysql$(date +%Y%m%d_%H%M%S)_bak
# sudo mv /var/lib/mysql /var/lib/mysql$(date +%Y%m%d_%H%M%S)_bak
# sudo ln -s ~/clh/db/mysql /var/lib/mysql
# sudo start mysql






















































纯命令式操作完成，依赖网络。 安装composer.phar

curl -s http://getcomposer.org/installer | php
//或者
php -r "readfile('https://getcomposer.org/installer');" | php

安装symfony框架

php composer.phar create-project symfony/framework-standard-edition path/to/install

如果下载了代码包，建议更改目录文件所属权

chown www-data:www-data install.log

php 可以省略

composer.phar update //可以用来更新项目组件代码

composer.phar update --prefer-dist //结尾参数可以让更新或者下载速度更快，以压缩包的形式下载好以后解压进行创建或者更新升级操作。

查看命令列表

php app/console

创建bundle

php ./app/console generate:bundle --namespace="Deepin\DeepinID\UserBundle" --dir="src/" --format="yml" --no-interaction

关于doctrine:entity命令

php ./app/console generate:doctrine:entity --entity="DeepinDeepinIDUserBundle:UserLoginlog" 生成指定entity
php app/console doctrine:schema:update  这行并不会真正执行，只是计算下需要执行多少条sql语句
php app/console doctrine:schema:update --dump-sql 将要执行的sql语句打印到命令行
php app/console doctrine:schema:update --force 执行，这才是真正的执行

自己编写或者修改的的entity类似这样

<?php

namespace Deepin\DeepinID\UserBundle\Entity;

use Doctrine\ORM\Mapping as ORM;



/**
 * User
 *
 * @ORM\Tabl e(
 *      name="user",
 *      uniqueConstraints={
 *          @ORM\UniqueConstraint(name="username_unique", columns={"username"}),
 *          @ORM\UniqueConstraint(name="email_unique", columns={"email"})
 *      }
 * )
 * @ORM\Entity
 */
class User
{
    private $id;
    private $username;
    private $password;
    private $email;
    private $mobile;
}

创建model

php app/console doctrine:generate:entities Acme/StoreBundle/Entity/Product 创建一个model

php app/console doctrine:generate:entities Deepin 创建多个model

创建from

php app/console doctrine:generate:form Deepin\DeepinID\UserBundle:User

刷新缓存

sudo -u www-data php app/console cache:clear --env=prod

翻译

sudo -u www-data php app/console translation:update --output-format="yml" --dump-messages --force --clean en DeepinIDUserBundle

调试

控制器中
\Doctrine\Common\Util\Debug::dump($form);

模板中
{{ dump(form) }}

前端素材

php app/console assets:install --symlink

单元测试

phpunit -c app/ src/Deepin

单元测试示例，test/controller

public function Common($get_url,$filter,$autologin=false)
{
    if ($autologin) {
        # Simulation of the login operation

    }
    $client = static::createClient();
    $crawler = $client->request('GET', $get_url);
    $contains=$client->getContainer()->get('translator')->trans('deepinid.user.'.$filter);
    // echo($get_url.' '.$contains."\n");
    $this->assertTrue($crawler->filter('html:contains("'.$contains.'")')->count() > 0);
}
public function testLogin(){
    $this->Common('/login','deepin_user_center');
}

实体关联

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\ORM\Mapping as ORM;
class User implements UserInterface, \Serializable
{
    private $isActive;

    public function __construct()
    {
    	$this->userInfo = new ArrayCollection();
        $this->isActive = true;
        // ......
    }

    /**
     * @ORM\OneToOne(targetEntity = "UserInfo")
     * @ORM\JoinColumn(name = "id", referencedColumnName = "id")
     **/
    private $userInfo;

    public function setUserInfo($userInfo)
    {
        $this->userInfo = $userInfo;
        return $this;
    }

    public function getUserInfo()
    {
        return $this->userInfo;
    }
}









git review <branch_name>
将本地分支branch_name提交到审阅服务器
如果本地工作区是不干净的 那就要使用stash暂存修改

git clone --no-checkout 'ssh://chenlianghong@121.40.93.113:29418/website-common' '/home/lee/clh/www/deepinid/vendor/deepin/common/Deepin/CommonBundle' && cd '/home/lee/clh/www/deepinid/vendor/deepin/common/Deepin/CommonBundle' && git remote add composer 'ssh://chenlianghong@121.40.93.113:29418/website-common' && git fetch composer
