

###################################
#可采用多个线程进行浏览器爬虫，镜像可以挂载在不同节点
#https://github.com/SeleniumHQ/docker-selenium
# docker run -d -p 4444:4444 -e SE_NODE_MAX_SESSIONS=8 -e SE_NODE_OVERRIDE_MAX_SESSIONS=true --shm-size="8g" selenium/standalone-firefox
###################################


import threading
from queue import Queue, Empty
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.firefox.options import Options as FirefoxOptions
import time
from selenium.common.exceptions import TimeoutException, WebDriverException

class PubChemSpider(threading.Thread):
    def __init__(self, task_queue, result_queue, thread_id):
        super().__init__()
        self.task_queue = task_queue
        self.result_queue = result_queue
        self.thread_id = thread_id
        
    def create_driver(self):
        options = FirefoxOptions()
        options.add_argument('--headless')
        driver = webdriver.Remote(
            command_executor='http://192.161.30.206:4444/wd/hub',
            options=options
        )
        # 设置隐式等待时间
        driver.implicitly_wait(10)
        return driver
        
    def get_kegg_link(self, driver, compound_id, max_retries=3):
        for attempt in range(max_retries):
            try:
                url = f"https://pubchem.ncbi.nlm.nih.gov/compound/{compound_id}"
                driver.get(url)
                
                kegg_link = WebDriverWait(driver, 20).until(
                    EC.presence_of_element_located((By.XPATH, "//a[contains(@href, 'kegg.jp/entry')]"))
                )
                
                return {
                    'compound_id': compound_id,
                    'link_text': kegg_link.text,
                    'href': kegg_link.get_attribute('href')
                }
            except (TimeoutException, WebDriverException) as e:
                print(f"Thread-{self.thread_id}: Attempt {attempt + 1} failed for compound {compound_id}: {str(e)}")
                if attempt == max_retries - 1:
                    raise
                time.sleep(2)  # 重试前等待
                
    def run(self):
        print(f"Thread-{self.thread_id} started")
        driver = None
        try:
            driver = self.create_driver()
            while True:
                try:
                    compound_id = self.task_queue.get_nowait()
                    try:
                        print(f"Thread-{self.thread_id} processing compound {compound_id}")
                        result = self.get_kegg_link(driver, compound_id)
                        self.result_queue.put(result)
                        print(f"Thread-{self.thread_id} successfully processed compound {compound_id}")
                    except Exception as e:
                        print(f"Thread-{self.thread_id} error processing compound {compound_id}: {str(e)}")
                        self.result_queue.put({
                            'compound_id': compound_id,
                            'error': str(e)
                        })
                    finally:
                        self.task_queue.task_done()
                except Empty:
                    print(f"Thread-{self.thread_id} finished - no more tasks")
                    break
        finally:
            if driver:
                driver.quit()
                print(f"Thread-{self.thread_id} closed browser")

def main():
    task_queue = Queue()
    result_queue = Queue()
    
    # 添加要爬取的化合物ID
    compound_ids = [702, 2244, 3033, 123631,5555]
    for cid in compound_ids:
        print(cid)
        task_queue.put(cid)
    
    # 创建并启动多个爬虫线程
    threads = []
    thread_count = 3  # 设置线程数
    for i in range(thread_count):
        spider = PubChemSpider(task_queue, result_queue, i+1)
        spider.start()
        threads.append(spider)
    
    # 等待所有任务完成
    task_queue.join()
    
    # 获取并打印结果
    results = []
    while not result_queue.empty():
        result = result_queue.get()
        results.append(result)
    
    print("\n=== Final Results ===")
    for result in sorted(results, key=lambda x: x['compound_id']):
        print(result)

if __name__ == '__main__':
    start_time = time.time()
    main()
    end_time = time.time()
    print(f"\nTotal execution time: {end_time - start_time:.2f} seconds")
