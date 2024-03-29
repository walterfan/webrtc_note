##########
selenium
##########


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** selenium
**Authors**  Walter Fan
**Category** LearningNote
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

What
==============
它是一个自动化测试工具集，包含

1. Selenium IDE

其实是一个 Chrome/Firefox 的扩展, 可以在浏览器中对页面操作进行方便的录制和回放.

2. Selenium Web driver

可以在本地或远程电脑上以原生方式驱动浏览器的操作

3. Selenium Grid

支持在多台机器上同时运行多个基于 Web Driver 的测试

4. Appium

这是基于 Web Driver 标准的开源工具,可用于移动设备 native/web app 的自动化测试

How
==============
以 Chrome 为例, 先查看你的浏览器版本, 到 https://chromedriver.chromium.org/downloads 上下载对应版本的 web driver

比如我的 mac m1 就下载 chromedriver_mac_arm64.zip, 放在公共路径下

或者干脆就用下面的自动下载功能

.. code-block:: python

   #!/usr/bin/env python3
   import chromedriver_autoinstaller
   chromedriver_autoinstaller.install()

   from selenium import webdriver
   from selenium.webdriver.common.by import By
   from selenium.webdriver.common.keys import Keys
   from selenium.webdriver.support import expected_conditions
   from selenium.webdriver.support.wait import WebDriverWait
   from selenium.common.exceptions import NoSuchElementException
   from selenium.common.exceptions import StaleElementReferenceException
   from bs4 import BeautifulSoup

   #driver = webdriver.Firefox()
   driver = webdriver.Chrome()
   driver.get("http://www.baidu.com")

   assert "百度" in driver.title
   query_text = "WebRTC"
   input_box = driver.find_element(By.ID, "kw")
   input_box.clear()
   input_box.send_keys(query_text)

   submit_btn = driver.find_element(By.ID, "su")
   submit_btn.click()

   ignored_exceptions = (NoSuchElementException, StaleElementReferenceException,)
   try:
      WebDriverWait(driver, 10, ignored_exceptions=ignored_exceptions) \
                  .until(expected_conditions.title_contains(query_text))
   except:
      pass

   # Using beautifulsop to parse search results
   bsobj = BeautifulSoup(driver.page_source, features="html.parser")

   # Get search results queue
   search_results = bsobj.find_all('div', {'class': 'c-container'})
   print("result count: {}".format(len(search_results)))
   # For each search result
   for search_item in search_results:
      if search_item.h3 and search_item.h3.a:
         # Get all text for the title of each search result
         text = search_item.h3.a.get_text(strip=True)
         print(text)

   driver.close()


Why
==============

