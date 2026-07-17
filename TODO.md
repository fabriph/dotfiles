

avoid closing iTerm with cmd+q
or ask comfirmation



--

when bashrc opens, record exeuction load time of the big blocks (eg Notion, Git, etc)

--


backup prompts?

--


skill create a plan
--
skill create a task list with template
--
skill spin a coding agent, ask it to update the task list with status, comments.

--

Answer this question. Create a plan.
Is there a way to create an interactive checklist before or while doing a git commit? There are certain things I want to verify and remind myself every time I commit into a repo. Alternatively, if I change a file I want to know to change another. For example, if I update the agent.md file, I also want to be reminded to change the equivalent for cloud.

One of the reminders needs to be that whenever I change the AGENTS.md I would like AI to proofread it, make sure it makes sense, and perhaps express it in a simpler and more clear way for AI to understand it, but also for me to review it at a later point.

The other reminder is what I already said, that whenever I change the configuration for Claude, I want it to also be changed for Codex.


--

SAME FOR CLAUDE
Is there a way for me to know that you correctly loaded the agent.MD file? For example, can I ask you to print a greeting message that is custom when you start?

--

when asking a coding agent to do work, if it's not trivial work, I'd like it to be in indivdual commits per milestones or tasks, so I can review them easily. On the other hand, if the final result is a massive diff, it's hard to review.




--



Spawn a coding agent with gpt-5.2-codex Reasoning Level Extra high to execute ai-tools/runs/2026-02-21_ai-tools-install-script/plan-v1.md
  Let it ask you questions if it has any, answer the questions and let the coding agent do
  its work. Continue until all work in the workplan has been completed. Ask the coding agent
  to mark the plan with status (done, skipped, etc) and comments (anything that learnt from
  it or any other relevant things to mention aboit it).
  Once work is completed, I want you to review the generated code and compare it to the plan, how did it do?



  --

  spec-driven development

What goes in a spec?
- Context: what/why
- Implementation details: how
- Verification