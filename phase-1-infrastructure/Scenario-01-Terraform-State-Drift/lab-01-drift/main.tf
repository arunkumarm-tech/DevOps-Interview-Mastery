resource "local_file" "devops_note" {
  content  = "Phase 1: Troubleshooting"
  filename = "${path.module}/note.txt"
}
