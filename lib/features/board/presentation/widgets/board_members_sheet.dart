import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slapp/core/theme/slap_colors.dart';
import 'package:slapp/features/board/data/models/board_member_model.dart';
import 'package:slapp/features/board/data/repositories/board_repository.dart';
import 'package:slapp/main.dart';

/// Bottom sheet for viewing and managing board members
class BoardMembersSheet extends ConsumerStatefulWidget {
  final String boardId;
  final String boardName;

  const BoardMembersSheet({
    super.key,
    required this.boardId,
    required this.boardName,
  });

  @override
  ConsumerState<BoardMembersSheet> createState() => _BoardMembersSheetState();
}

class _BoardMembersSheetState extends ConsumerState<BoardMembersSheet> {
  List<BoardMember> _members = [];
  bool _isLoading = true;
  bool _isInviting = false;
  final _phoneController = TextEditingController();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = supabase.auth.currentUser?.id;
    _loadMembers();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    
    try {
      final repo = BoardRepository();
      final membersData = await repo.getBoardMembers(widget.boardId);
      
      setState(() {
        _members = membersData.map((m) => BoardMember.fromJson(m)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading members: $e'),
            backgroundColor: SlapColors.error,
          ),
        );
      }
    }
  }

  void _showInviteDialog() {
    _phoneController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SlapColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_add, color: SlapColors.primary),
            ),
            const SizedBox(width: 12),
            const Text('Invite Member'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the phone number of the person you want to invite:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: '+1 (555) 123-4567',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          StatefulBuilder(
            builder: (context, setDialogState) => FilledButton(
              onPressed: _isInviting
                  ? null
                  : () async {
                      final phone = _phoneController.text.trim();
                      if (phone.isEmpty) return;
                      
                      setDialogState(() => _isInviting = true);
                      
                      try {
                        final repo = BoardRepository();
                        await repo.inviteMember(widget.boardId, phone);
                        
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text('Invited $phone to the board!'),
                                ],
                              ),
                              backgroundColor: SlapColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                          _loadMembers();
                        }
                      } catch (e) {
                        setDialogState(() => _isInviting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: SlapColors.error,
                            ),
                          );
                        }
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: SlapColors.primary,
              ),
              child: _isInviting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Invite'),
            ),
          ),
        ],
      ),
    );
  }

  void _showMemberOptions(BoardMember member) {
    // Check if current user is admin
    final currentUserIsAdmin = _members.any(
      (m) => m.odId == _currentUserId && m.isAdmin,
    );
    
    if (!currentUserIsAdmin || member.odId == _currentUserId) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              member.displayName,
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Change Role
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SlapColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  member.isAdmin ? Icons.person : Icons.admin_panel_settings,
                  color: SlapColors.secondary,
                ),
              ),
              title: Text(member.isAdmin ? 'Make Member' : 'Make Admin'),
              subtitle: Text(
                member.isAdmin
                    ? 'Remove admin privileges'
                    : 'Grant admin privileges',
              ),
              onTap: () async {
                Navigator.pop(context);
                await _changeRole(member);
              },
            ),
            
            // Remove from board
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SlapColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_remove,
                  color: SlapColors.error,
                ),
              ),
              title: const Text('Remove from Board'),
              subtitle: const Text('They will lose access'),
              onTap: () async {
                Navigator.pop(context);
                await _removeMember(member);
              },
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _changeRole(BoardMember member) async {
    try {
      final newRole = member.isAdmin ? 'member' : 'admin';
      
      await supabase.from('board_members').update({
        'role': newRole,
      }).eq('board_id', widget.boardId).eq('user_id', member.odId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('${member.displayName} is now a $newRole'),
              ],
            ),
            backgroundColor: SlapColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        _loadMembers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: SlapColors.error,
          ),
        );
      }
    }
  }

  Future<void> _removeMember(BoardMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: SlapColors.error),
            SizedBox(width: 12),
            Text('Remove Member'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove ${member.displayName} from this board?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: SlapColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      await supabase
          .from('board_members')
          .delete()
          .eq('board_id', widget.boardId)
          .eq('user_id', member.odId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('${member.displayName} has been removed'),
              ],
            ),
            backgroundColor: SlapColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        _loadMembers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: SlapColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: SlapColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.group,
                    color: SlapColors.secondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Board Members',
                        style: GoogleFonts.fredoka(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.boardName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _showInviteDialog,
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Invite'),
                  style: FilledButton.styleFrom(
                    backgroundColor: SlapColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Members List
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else if (_members.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.group_off,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No members yet',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _members.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final member = _members[index];
                  final isCurrentUser = member.odId == _currentUserId;
                  
                  return ListTile(
                    onTap: () => _showMemberOptions(member),
                    leading: _buildAvatar(member),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: SlapColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'You',
                              style: TextStyle(
                                fontSize: 10,
                                color: SlapColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: member.phoneNumber != null
                        ? Text(member.phoneNumber!)
                        : null,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: member.isAdmin
                            ? SlapColors.primary.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        member.isAdmin ? 'Admin' : 'Member',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: member.isAdmin
                              ? SlapColors.primary
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildAvatar(BoardMember member) {
    if (member.avatarUrl != null && member.avatarUrl!.isNotEmpty) {
      // If it's an emoji avatar
      if (member.avatarUrl!.length <= 2) {
        return CircleAvatar(
          backgroundColor: SlapColors.accent.withOpacity(0.3),
          child: Text(
            member.avatarUrl!,
            style: const TextStyle(fontSize: 20),
          ),
        );
      }
      // If it's a URL
      return CircleAvatar(
        backgroundImage: NetworkImage(member.avatarUrl!),
        backgroundColor: SlapColors.accent.withOpacity(0.3),
      );
    }
    
    // Default to initials
    return CircleAvatar(
      backgroundColor: SlapColors.secondary.withOpacity(0.1),
      child: Text(
        member.initials,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: SlapColors.secondary,
        ),
      ),
    );
  }
}

/// Show the board members sheet
void showBoardMembersSheet(
  BuildContext context, {
  required String boardId,
  required String boardName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => BoardMembersSheet(
      boardId: boardId,
      boardName: boardName,
    ),
  );
}
