import os
import json
import lief
from capstone import Cs, CS_ARCH_X86, CS_MODE_64
from jinja2 import Environment, FileSystemLoader
import moviepy.editor as mpe
from gtts import gTTS
from smolagents import tool

@tool
def analyze_binary(filepath: str) -> str:
    """Analyzes a binary file using lief and capstone to show sections and disassembly."""
    try:
        binary = lief.parse(filepath)
        if not binary: return f"Error: Could not parse binary file at {filepath}"

        text = f"Binary Analysis for: {filepath}\n"
        text += f"Entrypoint: {hex(binary.entrypoint)}\n"
        text += f"Architecture: {binary.header.machine_type.name}\n\n"

        text += "Sections:\n"
        for section in binary.sections:
            text += f"- {section.name:<10} Size: {section.size:<8} Offset: {hex(section.offset)}\n"

        if binary.has_section('.text'):
            text_section = binary.get_section('.text')
            code = bytes(text_section.content)
            md = Cs(CS_ARCH_X86, CS_MODE_64)
            text += "\nDisassembly of .text section (first 15 instructions):\n"
            count = 0
            for i in md.disasm(code, text_section.virtual_address):
                text += f"0x{i.address:x}:\t{i.mnemonic}\t{i.op_str}\n"
                count += 1
                if count >= 15: break
        return text
    except Exception as e:
        return f"Error analyzing binary: {str(e)}"

@tool
def generate_website(template_dir: str, output_dir: str, context_json: str) -> str:
    """Generates a responsive website from a Jinja2 template directory and a JSON context."""
    try:
        if not os.path.isdir(template_dir):
            return f"Error: Template directory '{template_dir}' not found."

        context = json.loads(context_json)
        env = Environment(loader=FileSystemLoader(template_dir))
        template = env.get_template('index.html') # Assumes 'index.html' is the main template
        rendered_html = template.render(context)
        os.makedirs(output_dir, exist_ok=True)
        with open(os.path.join(output_dir, 'index.html'), 'w') as f:
            f.write(rendered_html)
        return f"Website successfully generated at {output_dir}/index.html"
    except json.JSONDecodeError:
        return "Error: Invalid JSON provided for context."
    except Exception as e:
        return f"Error generating website: {str(e)}"

@tool
def create_documentary_video(image_files_str: str, narration_text: str, output_file: str) -> str:
    """Creates a narrated documentary video from a comma-separated list of image files and a narration script."""
    try:
        image_files = [img.strip() for img in image_files_str.split(',')]
        clips = []
        for img_path in image_files:
            if os.path.exists(img_path):
                 clips.append(mpe.ImageClip(img_path).set_duration(5))
            else:
                print(f"[Warning] Image file not found, skipping: {img_path}")

        if not clips: return "Error: No valid image files found."

        video = mpe.concatenate_videoclips(clips, method="compose")

        tts = gTTS(text=narration_text, lang='en')
        audio_path = f"/tmp/temp_audio_{int(time.time())}.mp3"
        tts.save(audio_path)

        audio = mpe.AudioFileClip(audio_path)
        # Ensure audio is not longer than video
        if audio.duration > video.duration:
            audio = audio.subclip(0, video.duration)

        final_video = video.set_audio(audio)
        final_video.write_videofile(output_file, fps=24, codec='libx264')

        os.remove(audio_path)
        return f"Documentary video successfully saved to {output_file}"
    except Exception as e:
        return f"Error creating video: {str(e)}"
