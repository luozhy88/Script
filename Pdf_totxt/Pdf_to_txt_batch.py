
############################################
#https://ds4sd.github.io/docling/examples/batch_convert
#install pip install docling --index-url https://pypi.tuna.tsinghua.edu.cn/simple   --extra-index-url https://download.pytorch.org/whl/cpu
#input_doc_path为输入pdf文件
#artifacts_path下载好的模型，最好打开科学
###export HF_ENDPOINT=https://hf-mirror.com
###git clone https://hf-mirror.com/ds4sd/docling-models
### 节点7测试
############################################



import json
import logging
import time
from pathlib import Path

from docling.datamodel.base_models import InputFormat
from docling.datamodel.pipeline_options import PdfPipelineOptions 
from docling.document_converter import DocumentConverter, PdfFormatOption

def convert_pdf(input_path: Path, output_dir: Path, doc_converter: DocumentConverter):
    """转换单个PDF文件"""
    start_time = time.time()
    conv_result = doc_converter.convert(input_path)
    end_time = time.time() - start_time
    
    logging.info(f"文档 {input_path.name} 转换完成,用时 {end_time:.2f} 秒")

    doc_filename = conv_result.input.file.stem
    
    # 导出各种格式
    formats = {
        'json': conv_result.document.export_to_dict,
        'txt': conv_result.document.export_to_text,
        'md': conv_result.document.export_to_markdown,
        'doctags': conv_result.document.export_to_document_tokens
    }
    
    for ext, export_func in formats.items():
        output_file = output_dir / f"{doc_filename}.{ext}"
        with output_file.open("w", encoding="utf-8") as fp:
            content = export_func()
            if ext == 'json':
                content = json.dumps(content)
            fp.write(content)

def batch_convert_pdfs(input_dir: Path, output_dir: Path, artifacts_path: Path):
    """批量转换目录下的所有PDF文件"""
    # 创建输出目录
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # 配置转换器
    pipeline_options = PdfPipelineOptions(artifacts_path=artifacts_path)
    doc_converter = DocumentConverter(
        format_options={
            InputFormat.PDF: PdfFormatOption(pipeline_options=pipeline_options)
        }
    )
    
    # 获取所有PDF文件
    pdf_files = list(input_dir.glob("**/*.pdf"))
    total_files = len(pdf_files)
    
    if total_files == 0:
        logging.warning(f"在目录 {input_dir} 下未找到PDF文件")
        return
        
    logging.info(f"开始处理 {total_files} 个PDF文件...")
    
    # 批量转换
    for i, pdf_file in enumerate(pdf_files, 1):
        logging.info(f"正在处理第 {i}/{total_files} 个文件: {pdf_file.name}")
        try:
            convert_pdf(pdf_file, output_dir, doc_converter)
        except Exception as e:
            logging.error(f"处理文件 {pdf_file.name} 时出错: {str(e)}")

def main():
    # 配置日志
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    
    # 设置路径
    input_dir = Path("/home/zhiyu/data/test10")  # PDF文件所在目录
    output_dir = Path("scratch")  # 输出目录
    artifacts_path = Path("/home/zhiyu/data/test10/docling-model")  # 模型目录
    
    # 执行批量转换
    batch_convert_pdfs(input_dir, output_dir, artifacts_path)

if __name__ == "__main__":
    main()
