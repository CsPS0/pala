// One icon per concept, used the same way on the landing page, docs, history page and footer.
import { AppWindow, BookOpen, Download, History, Monitor, Puzzle, Search, ShieldCheck, Smartphone, Terminal } from "lucide-react";
import { GitHubIcon } from "@/components/PlatformIcons";

export const CONCEPT_ICONS = {
  desktop: Monitor,
  phone: Smartphone,
  extension: Puzzle,
  terminal: Terminal,
  web: AppWindow,
  download: Download,
  docs: BookOpen,
  privacy: ShieldCheck,
  history: History,
  search: Search,
  github: GitHubIcon,
};
