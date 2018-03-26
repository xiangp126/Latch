Problem: wget link of JDK/Tomcat always expire on Oracle official website
So store them on repository itself

------------------------------------- git-lfs
git lfs - large file storage
brew install git-lfs
```bash
git lfs install
git lfs track "*.tar.gz"

git add packages/
git add .gitattributes

> cat .gitattributes
*.tar.gz filter=lfs diff=lfs merge=lfs -text

git lfs ls-files
ad78d0908a * packages/apache-tomcat-8.5.27.tar.gz
6dbc56a0e3 * packages/jdk-8u161-linux-x64.tar.gz
```
