import threading
import time
import logging
from typing import List, Dict, Any

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger('ReflectionDaemon')

class SelfReflectionDaemon(threading.Thread):
    """
    A continuous daemon that processes recent episodic memories into generalized
    'lessons learned' and stores them as long-term knowledge vectors.
    """
    def __init__(self, memory, llm, lookback_limit: int = 20, reflection_interval_sec: int = 300):
        super().__init__()
        self.memory = memory
        self.llm = llm # This is the CodeAgent's model instance
        self.lookback_limit = lookback_limit
        self.reflection_interval_sec = reflection_interval_sec
        self.stop_event = threading.Event()
        self.daemon = True
        logger.info("Self-Reflection Daemon initialized.")

    def _generate_reflection_prompt(self, recent_episodes: List[Dict[str, Any]]) -> str:
        episodes_text = "\n---\n".join([
            f"Task: {e.get('summary', 'N/A')}" for e in recent_episodes
        ])

        prompt = (
            f"Analyze the following {len(recent_episodes)} recent operational episodes from the SkyscopeOS agent. "
            "Identify recurring patterns, common failure points, or major successes. "
            "Formulate a concise 'Lesson Learned' and a corresponding 'Strategic Policy Adjustment' in a single paragraph. "
            "The focus should be on improving future decision-making and tool-use efficiency.\n\n"
            f"RECENT EPISODES:\n{episodes_text}"
        )
        return prompt

    def run(self):
        # Allow some time for the main application to start up
        time.sleep(15)
        while not self.stop_event.is_set():
            try:
                # This is a conceptual implementation. A real system might need a more robust way
                # to get "recent" items, e.g., querying by timestamp. For now, we search for a generic term.
                recent_episodes_text = self.memory.search(query="recent tasks and outcomes", topk=self.lookback_limit)

                if "No memories found" in recent_episodes_text or not recent_episodes_text.strip():
                    logger.debug("No new episodes to reflect upon.")
                    time.sleep(self.reflection_interval_sec)
                    continue

                # Parse the search results into a list of dictionaries
                lines = recent_episodes_text.splitlines()
                # Skip the header line ("Relevant Memories:")
                if lines and "Relevant Memories:" in lines[0]:
                    lines = lines[1:]

                recent_episodes = [{"summary": line.strip("- ").split('(Score:')[0].strip()} for line in lines]

                if not recent_episodes:
                    time.sleep(self.reflection_interval_sec)
                    continue

                # 2. Generate the reflection prompt
                reflection_prompt = self._generate_reflection_prompt(recent_episodes)

                # 3. Call the LLM for deep reflection
                response = self.llm.generate([{"role": "user", "content": reflection_prompt}])
                reflection_text = response.content

                # 4. Store the output as Long-Term Knowledge (conceptual)
                if reflection_text:
                    # In a fully integrated system, this would call the knowledge_stack.add method.
                    # For now, we log it to demonstrate the functionality.
                    logger.info(f"Generated Reflection to be stored in Knowledge Stack: '{reflection_text}'")
                    # Example of direct integration if knowledge_stack were passed in:
                    # self.knowledge_stack.add(f"reflection_{int(time.time())}", "Strategic Reflection", reflection_text)
            except Exception as e:
                logger.error(f"Error during self-reflection process: {e}", exc_info=True)

            time.sleep(self.reflection_interval_sec)

    def stop(self):
        self.stop_event.set()
        logger.info("Self-Reflection Daemon shutting down.")
